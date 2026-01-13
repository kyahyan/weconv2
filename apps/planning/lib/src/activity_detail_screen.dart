import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'components/form_builder_dialog.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity? activity;

  const ActivityDetailScreen({super.key, this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityRepo = ActivityRepository();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  late DateTime _startTime;
  late DateTime _endTime;
  bool _isRegistrationRequired = false;
  ActivityFormConfig? _formConfig;
  
  File? _imageFile;
  final _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activity?.title ?? '');
    _descriptionController = TextEditingController(text: widget.activity?.description ?? '');
    _locationController = TextEditingController(text: widget.activity?.location ?? '');
    
    _startTime = widget.activity?.startTime.toLocal() ?? DateTime.now();
    _endTime = widget.activity?.endTime.toLocal() ?? DateTime.now().add(const Duration(hours: 2));
    _isRegistrationRequired = widget.activity?.isRegistrationRequired ?? false;
    _formConfig = widget.activity?.formConfig;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate Time
    if (_endTime.isBefore(_startTime)) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Invalid Time'),
          description: Text('End time must be after start time'),
        )
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final activity = Activity(
        id: widget.activity?.id ?? '', // ID handled by DB for new
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        startTime: _startTime,
        endTime: _endTime,
        isRegistrationRequired: _isRegistrationRequired,
        imageUrl: widget.activity?.imageUrl, // Keep existing URL unless new image uploaded
        formConfig: _formConfig,
      );

      if (widget.activity != null) {
        await _activityRepo.updateActivity(activity, _imageFile);
      } else {
        await _activityRepo.createActivity(activity, _imageFile);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
         ShadToaster.of(context).show(
           ShadToast.destructive(
             title: const Text('Error'),
             description: Text(e.toString()),
           )
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity == null ? 'Create Activity' : 'Edit Activity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : (widget.activity?.imageUrl != null
                            ? DecorationImage(image: NetworkImage(widget.activity!.imageUrl!), fit: BoxFit.cover)
                            : null),
                  ),
                  child: _imageFile == null && widget.activity?.imageUrl == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.white70),
                            SizedBox(height: 8),
                            Text("Upload Cover Image", style: TextStyle(color: Colors.white70)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Activity Title', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                   Expanded(
                     child: _buildDateTimePicker('Starts', _startTime, (val) {
                       setState(() {
                         final duration = _endTime.difference(_startTime);
                         _startTime = val;
                         _endTime = val.add(duration);
                       });
                     }),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: _buildDateTimePicker('Ends', _endTime, (val) => setState(() => _endTime = val)),
                   ),
                ],
              ),
              const SizedBox(height: 16),

              // Options
              SwitchListTile(
                title: const Text('Registration Required'),
                subtitle: const Text('Generates QR code for check-in'),
                value: _isRegistrationRequired,
                onChanged: (val) => setState(() => _isRegistrationRequired = val),
              ),
              
              if (_isRegistrationRequired) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           const Text("Custom Registration Fields", style: TextStyle(fontWeight: FontWeight.bold)),
                           TextButton(
                             onPressed: () async {
                               final config = await Navigator.push(
                                 context,
                                 MaterialPageRoute(builder: (_) => FormBuilderDialog(initialConfig: _formConfig)),
                               );
                               if (config != null && config is ActivityFormConfig) {
                                 setState(() {
                                   _formConfig = config;
                                 });
                               }
                             },
                             child: const Text("Customize Form"),
                           ),
                        ],
                      ),
                      if (_formConfig != null && _formConfig!.fields.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _formConfig!.fields.map((f) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(_getIconForType(f.type), size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text('${f.label} (${f.type})', style: const TextStyle(color: Colors.grey)),
                                if (f.isRequired) const Text(' *', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          )).toList(),
                        )
                      else 
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text("No custom fields configured. Users will only provide basic info.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveActivity,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Save Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(String label, DateTime current, Function(DateTime) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context, 
              initialDate: current, 
              firstDate: DateTime(2024), 
              lastDate: DateTime(2030)
            );
            if (date != null && context.mounted) {
              final time = await showTimePicker(
                context: context, 
                initialTime: TimeOfDay.fromDateTime(current)
              );
              if (time != null) {
                onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            child: Row(
               children: [
                 const Icon(Icons.calendar_today, size: 16),
                 const SizedBox(width: 8),
                 Text(DateFormat('MMM d, h:mm a').format(current)),
               ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'text': return Icons.text_fields;
      case 'number': return Icons.numbers;
      case 'dropdown': return Icons.arrow_drop_down_circle;
      case 'date': return Icons.calendar_today;
      case 'boolean': return Icons.check_box;
      default: return Icons.help_outline;
    }
  }
}
