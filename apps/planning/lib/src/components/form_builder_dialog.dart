import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:uuid/uuid.dart';

class FormBuilderDialog extends StatefulWidget {
  final ActivityFormConfig? initialConfig;

  const FormBuilderDialog({super.key, this.initialConfig});

  @override
  State<FormBuilderDialog> createState() => _FormBuilderDialogState();
}

class _FormBuilderDialogState extends State<FormBuilderDialog> {
  late List<ActivityFormField> _fields;

  @override
  void initState() {
    super.initState();
    _fields = widget.initialConfig?.fields != null 
        ? List.from(widget.initialConfig!.fields) 
        : [];
  }

  void _addField() {
    showDialog(
      context: context,
      builder: (ctx) => _AddFieldDialog(
        onSave: (field) {
          setState(() {
            _fields.add(field);
          });
        },
      ),
    );
  }

  void _editField(int index) {
     showDialog(
      context: context,
      builder: (ctx) => _AddFieldDialog(
        initialField: _fields[index],
        onSave: (field) {
          setState(() {
            _fields[index] = field;
          });
        },
      ),
    );
  }

  void _deleteField(int index) {
    setState(() {
      _fields.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Form'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, ActivityFormConfig(fields: _fields));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _fields.isEmpty
                ? const Center(child: Text("No fields added yet."))
                : ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = _fields.removeAt(oldIndex);
                        _fields.insert(newIndex, item);
                      });
                    },
                    children: [
                      for (int i = 0; i < _fields.length; i++)
                        ListTile(
                          key: ValueKey(_fields[i].id),
                          title: Text(_fields[i].label),
                          subtitle: Text('Type: ${_fields[i].type} ${_fields[i].isRequired ? "(Required)" : ""}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editField(i)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteField(i)),
                              const Icon(Icons.drag_handle),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _addField,
                icon: const Icon(Icons.add),
                label: const Text('Add Field'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFieldDialog extends StatefulWidget {
  final ActivityFormField? initialField;
  final Function(ActivityFormField) onSave;

  const _AddFieldDialog({this.initialField, required this.onSave});

  @override
  State<_AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<_AddFieldDialog> {
  late TextEditingController _labelController;
  late TextEditingController _optionsController;
  String _type = 'text';
  bool _isRequired = false;
  
  final _types = ['text', 'number', 'dropdown', 'date', 'boolean'];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialField?.label ?? '');
    _optionsController = TextEditingController(text: widget.initialField?.options?.join(',') ?? '');
    _type = widget.initialField?.type ?? 'text';
    _isRequired = widget.initialField?.isRequired ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialField == null ? 'Add Field' : 'Edit Field'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _type = val!),
            ),
            if (_type == 'dropdown') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _optionsController,
                decoration: const InputDecoration(labelText: 'Options (comma separated)'),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Required'),
              value: _isRequired,
              onChanged: (val) => setState(() => _isRequired = val),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (_labelController.text.isEmpty) return;
            
            final field = ActivityFormField(
              id: widget.initialField?.id,
              label: _labelController.text,
              type: _type,
              isRequired: _isRequired,
              options: _type == 'dropdown' 
                  ? _optionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList() 
                  : null,
            );
            widget.onSave(field);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
