import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:image_picker/image_picker.dart';

class OrganizationInfoForm extends StatefulWidget {
  final Organization organization;
  final Function(Organization) onSave;
  final Function(List<int> bytes, String extension) onUploadAvatar;
  final bool isLoading;

  const OrganizationInfoForm({
    super.key,
    required this.organization,
    required this.onSave,
    required this.onUploadAvatar,
    this.isLoading = false,
  });

  @override
  State<OrganizationInfoForm> createState() => _OrganizationInfoFormState();
}

class _OrganizationInfoFormState extends State<OrganizationInfoForm> {
  late TextEditingController _nameController;
  late TextEditingController _acronymController;
  late TextEditingController _contactMobileController;
  late TextEditingController _contactLandlineController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  
  // Social media placeholders
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;

  @override
  void initState() {
    super.initState();
    final org = widget.organization;
    _nameController = TextEditingController(text: org.name);
    _acronymController = TextEditingController(text: org.acronym);
    _contactMobileController = TextEditingController(text: org.contactMobile);
    _contactLandlineController = TextEditingController(text: org.contactLandline);
    _locationController = TextEditingController(text: org.location);
    _websiteController = TextEditingController(text: org.website);

    final socials = org.socialMediaLinks ?? {};
    _facebookController = TextEditingController(text: socials['facebook'] as String?);
    _instagramController = TextEditingController(text: socials['instagram'] as String?);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _acronymController.dispose();
    _contactMobileController.dispose();
    _contactLandlineController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.name.split('.').last;
      widget.onUploadAvatar(bytes, extension);
    }
  }

  void _handleSubmit() {
    final socials = {
      'facebook': _facebookController.text.trim(),
      'instagram': _instagramController.text.trim(),
    };
    // remove empty keys
    socials.removeWhere((key, value) => (value as String).isEmpty);

    final updatedOrg = Organization(
      id: widget.organization.id,
      name: _nameController.text.trim(),
      ownerId: widget.organization.ownerId,
      createdAt: widget.organization.createdAt,
      status: widget.organization.status,
      acronym: _acronymController.text.trim().isEmpty ? null : _acronymController.text.trim(),
      contactMobile: _contactMobileController.text.trim().isEmpty ? null : _contactMobileController.text.trim(),
      contactLandline: _contactLandlineController.text.trim().isEmpty ? null : _contactLandlineController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      avatarUrl: widget.organization.avatarUrl, // Avatar is updated separately via callback
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      socialMediaLinks: socials.isEmpty ? null : socials,
    );

    widget.onSave(updatedOrg);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Stack(
            children: [
               CircleAvatar(
                 radius: 40,
                 backgroundImage: widget.organization.avatarUrl != null 
                     ? NetworkImage(widget.organization.avatarUrl!) 
                     : null,
                 child: widget.organization.avatarUrl == null 
                     ? const Icon(Icons.business, size: 40) 
                     : null,
               ),
               Positioned(
                 right: 0,
                 bottom: 0,
                 child: IconButton(
                    onPressed: _pickImage,
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 12, // small icon
                      child: Icon(Icons.edit, size: 14, color: Colors.blue),
                    ),
                 ),
               ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Organization Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _acronymController,
          decoration: const InputDecoration(labelText: 'Acronym (e.g. WFIM)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        const Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
           children: [
             Expanded(
               child: TextField(
                  controller: _contactMobileController,
                  decoration: const InputDecoration(labelText: 'Mobile', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_android)),
               ),
             ),
             const SizedBox(width: 10),
             Expanded(
               child: TextField(
                  controller: _contactLandlineController,
                  decoration: const InputDecoration(labelText: 'Landline', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
               ),
             ),
           ],
        ),
        const SizedBox(height: 10),
        TextField(
           controller: _locationController,
           decoration: const InputDecoration(labelText: 'Location / Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
        ),
        const SizedBox(height: 20),
        const Text('Online Presence', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
           controller: _websiteController,
           decoration: const InputDecoration(labelText: 'Website URL', border: OutlineInputBorder(), prefixIcon: Icon(Icons.language)),
        ),
        const SizedBox(height: 10),
        TextField(
           controller: _facebookController,
           decoration: const InputDecoration(labelText: 'Facebook Link', border: OutlineInputBorder(), prefixIcon: Icon(Icons.facebook)),
        ),
        const SizedBox(height: 10),
        TextField(
           controller: _instagramController,
           decoration: const InputDecoration(labelText: 'Instagram Link', border: OutlineInputBorder(), prefixIcon: Icon(Icons.camera_alt)),
        ),
        const SizedBox(height: 30),
        FilledButton(
          onPressed: _handleSubmit,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
