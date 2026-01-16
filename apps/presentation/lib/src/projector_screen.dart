import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemNavigator
import 'package:desktop_multi_window/desktop_multi_window.dart' as dmw;
import 'features/screens/models/projection_style.dart';

class ProjectorScreen extends StatefulWidget {
  final int windowId;
  final Map<String, dynamic>? args;

  const ProjectorScreen({
    super.key,
    required this.windowId,
    this.args,
  });

  @override
  State<ProjectorScreen> createState() => _ProjectorScreenState();
}

class _ProjectorScreenState extends State<ProjectorScreen> {
  String _currentText = '';
  ProjectionStyle _style = const ProjectionStyle();
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    if (widget.args != null) {
       if (widget.args!['name'] != null) {
          _currentText = widget.args!['name'];
       }
    }
    
    _initWindow();

    dmw.DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'updateSlide') {
        final data = call.arguments as String;
        try {
           final dynamic json = jsonDecode(data);
           if (json is Map) {
              setState(() {
                _currentText = json['content']?.toString() ?? '';
                // Apply style overrides from slide data
                _style = _style.copyWith(
                   isBold: json['isBold'] as bool? ?? _style.isBold,
                   isItalic: json['isItalic'] as bool? ?? _style.isItalic,
                   isUnderlined: json['isUnderlined'] as bool? ?? _style.isUnderlined,
                   align: _mapAlignment((json['alignment'] as num?)?.toInt() ?? 1),
                );
              });
           } else {
               // Double decode check?
               if (json is String) {
                   try {
                       final deepJson = jsonDecode(json);
                       if (deepJson is Map) {
                           setState(() {
                             _currentText = deepJson['content']?.toString() ?? '';
                             _style = _style.copyWith(
                                isBold: deepJson['isBold'] as bool? ?? _style.isBold,
                                isItalic: deepJson['isItalic'] as bool? ?? _style.isItalic,
                                isUnderlined: deepJson['isUnderlined'] as bool? ?? _style.isUnderlined,
                                align: _mapAlignment((deepJson['alignment'] as num?)?.toInt() ?? 1),
                             );
                           });
                           return;
                       }
                   } catch (_) {}
               }
              setState(() => _currentText = data);
           }
        } catch (e) {
             debugPrint("Error parsing updateSlide JSON: $e");
             // Show Error on Screen for Debugging
             setState(() => _currentText = "JSON Error: $e\nData: $data");
        }
      } else if (call.method == 'updateStyle') {
        try {
           final json = jsonDecode(call.arguments as String);
           setState(() {
             _style = ProjectionStyle.fromJson(json);
           });
        } catch (e) {
           debugPrint("Error parsing style update: $e");
        }
      }
      return null;
    });

    // Force a redraw after the first frame to ensure valid constraints are received
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) setState(() {});
    });
    
    // Backup kick for slow initializations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }
  
  Future<void> _initWindow() async {
     try {
       // Pull the initial state from the main window to avoid race conditions
       final result = await dmw.DesktopMultiWindow.invokeMethod(0, 'requestInitialState', widget.windowId);
       if (result != null) {
         final json = jsonDecode(result as String);
         if (mounted) {
           setState(() {
             String content = json['content'] ?? '';
             String name = json['name'] ?? widget.args?['name'] ?? '';
             
             // Fallback to name if content is empty
             _currentText = content.isNotEmpty ? content : name;
             
             if (json['style'] != null) {
                _style = ProjectionStyle.fromJson(json['style']);
             }
             
             if (json['slideData'] != null) {
                 final sData = json['slideData'];
                 // Override
                 _style = _style.copyWith(
                    isBold: sData['isBold'],
                    isItalic: sData['isItalic'],
                    isUnderlined: sData['isUnderlined'],
                    align: _mapAlignment(sData['alignment'] ?? 1),
                 );
             }
           });
         }
       }
     } catch (e) {
       debugPrint('Error fetching initial state: $e');
     }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(background: Colors.black),
      ),
      home: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: Scaffold(
          backgroundColor: Colors.black, // Ensure explicitly black
          body: Stack(
            fit: StackFit.expand, 
            children: [
               // Content
               LayoutBuilder(
                 builder: (context, constraints) {
                   // Guard against invalid constraints
                   if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                      return const ColoredBox(color: Colors.black);
                   }
                   
                   return Center(
                     child: Padding(
                       padding: const EdgeInsets.all(48.0),
                       child: _buildStyledText(constraints.maxWidth - 96, constraints.maxHeight - 96),
                     ),
                   );
                 }
               ),
              
              // Close Button (Visible on Hover)
              if (_isHovering)
                Positioned(
                   top: 16,
                   right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 32),
                    onPressed: () async {
                      try {
                        await dmw.DesktopMultiWindow.invokeMethod(0, 'requestClose', widget.windowId);
                      } catch (e) {
                        debugPrint('Failed to request close: $e');
                        SystemNavigator.pop();
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                      hoverColor: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledText(double maxWidth, double maxHeight) {
     if (maxWidth <= 0 || maxHeight <= 0) {
        return const SizedBox.shrink(); 
     }

     double fontSize = _style.fontSize;
     
     // Auto-scaling Logic
     if (_style.scaleMode != ScaleMode.fixed) {
        double maxSearchSize = _style.scaleMode == ScaleMode.textDown ? _style.fontSize : 500.0;
        fontSize = _findOptimalFontSize(maxWidth, maxHeight, maxSearchSize);
     }

     return Stack(
       children: [
         // The actual text
         Container(
            width: maxWidth,
            height: maxHeight,
            alignment: _resolveAlignment(_style.align),
            child: Text(
              _currentText,
              textAlign: _style.align,
              style: TextStyle(
                 fontFamily: _style.fontFamily,
                 fontSize: fontSize,
                 fontWeight: _style.isBold ? FontWeight.bold : FontWeight.normal,
                 fontStyle: _style.isItalic ? FontStyle.italic : FontStyle.normal,
                 color: _style.fontColor,
                 decoration: _style.isUnderlined ? TextDecoration.underline : TextDecoration.none,
                 height: 1.1, // Fix line height
              ),
            ),
         ),
         
         // Debug Info (Removed)
         // if (_isHovering) ...
       ],
     );
  }

  double _findOptimalFontSize(double maxWidth, double maxHeight, double maxFontSize) {
     double low = 10.0;
     double high = maxFontSize;
     double optimal = low;
     
     while (low <= high) {
        double mid = (low + high) / 2;
        if (_doesTextFit(mid, maxWidth, maxHeight)) {
           optimal = mid;
           low = mid + 1;
        } else {
           high = mid - 1;
        }
     }
     return optimal;
  }

  bool _doesTextFit(double fontSize, double maxWidth, double maxHeight) {
     final span = TextSpan(
        text: _currentText,
        style: TextStyle(
           fontFamily: _style.fontFamily,
           fontSize: fontSize,
           fontWeight: _style.isBold ? FontWeight.bold : FontWeight.normal,
           fontStyle: _style.isItalic ? FontStyle.italic : FontStyle.normal,
        ),
     );

     final painter = TextPainter(
        text: span,
        textAlign: _style.align,
        textDirection: TextDirection.ltr,
     );

     painter.layout(maxWidth: maxWidth);

     return painter.height <= maxHeight && painter.width <= maxWidth; 
  }

  Alignment _resolveAlignment(TextAlign align) {
     switch (align) {
        case TextAlign.left: return Alignment.centerLeft;
        case TextAlign.right: return Alignment.centerRight;
        case TextAlign.center: 
        case TextAlign.justify:
        default: return Alignment.center;
     }
  }

  TextAlign _mapAlignment(int val) {
     switch (val) {
        case 0: return TextAlign.left;
        case 2: return TextAlign.right;
        case 1: 
        default: return TextAlign.center;
     }
  }
}
