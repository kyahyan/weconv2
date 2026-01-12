import 'package:flutter/material.dart';
import 'package:models/models.dart';

class ProfileForm extends StatefulWidget {
  final UserProfile profile;
  final bool isLoading;
  final Future<void> Function(String fullName, String? address, String? contactNumber) onSave;
  final VoidCallback? onSignOut;
  final VoidCallback? onUploadImage;

  const ProfileForm({
    super.key,
    required this.profile,
    required this.onSave,
    this.isLoading = false,
    this.onSignOut,
    this.onUploadImage,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _addressController = TextEditingController(text: widget.profile.address);
    _contactController = TextEditingController(text: widget.profile.contactNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.profile.avatarUrl != null &&
                          widget.profile.avatarUrl!.isNotEmpty
                      ? NetworkImage(widget.profile.avatarUrl!)
                      : null,
                  child: widget.profile.avatarUrl == null ||
                          widget.profile.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: widget.onUploadImage,
                    icon: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt, size: 16, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Email: ${widget.profile.username ?? "Unknown"}',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(
              labelText: 'Contact Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: widget.isLoading
                ? null
                : () {
                    widget.onSave(
                      _nameController.text.trim(),
                      _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
                      _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
                    );
                  },
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Profile'),
          ),
          if (widget.onSignOut != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: widget.onSignOut,
              child: const Text('Sign Out'),
            ),
          ],
        ],
      ),
    );
  }
}
