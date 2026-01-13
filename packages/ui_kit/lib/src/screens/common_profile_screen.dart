import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import '../widgets/profile_form.dart'; // Import from sibling directory ../widgets/

class CommonProfileScreen extends StatefulWidget {
  const CommonProfileScreen({super.key});

  @override
  State<CommonProfileScreen> createState() => _CommonProfileScreenState();
}

class _CommonProfileScreenState extends State<CommonProfileScreen> {
  final _authService = AuthService();
  final _profileRepository = ProfileRepository();
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;
    try {
      final profile = await _profileRepository.getProfile(user.id);
      if (mounted) {
        setState(() {
          // If profile exists, use it. If not, create a temporary local one based on auth user
          _profile = profile ?? UserProfile(id: user.id, username: user.email);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile(String fullName, String? address, String? contactNumber) async {
    if (_profile == null) return;
    setState(() => _isLoading = true);
    try {
      final updatedProfile = UserProfile(
        id: _profile!.id,
        username: _profile!.username,
        avatarUrl: _profile!.avatarUrl, // Keep existing URL, it is updated separately via upload
        fullName: fullName,
        address: address,
        contactNumber: contactNumber,
      );
      await _profileRepository.updateProfile(updatedProfile);
      if (mounted) {
        setState(() {
          _profile = updatedProfile;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_profile == null) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final fileExtension = pickedFile.name.split('.').last;
      
      final url = await _profileRepository.uploadAvatar(
        _profile!.id,
        bytes.toList(),
        fileExtension,
      );

      // Let's create a temporary updated object
       final updatedProfile = UserProfile(
        id: _profile!.id,
        username: _profile!.username,
        fullName: _profile!.fullName,
        address: _profile!.address,
        contactNumber: _profile!.contactNumber,
        avatarUrl: url,
      );
      
      await _profileRepository.updateProfile(updatedProfile);

      if (mounted) {
         setState(() {
           _profile = updatedProfile;
           _isLoading = false;
         });
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated!')),
         );
      }
    } catch (e) {
       if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text("User not found"))
              : ProfileForm(
                  profile: _profile!,
                  isLoading: _isLoading,
                  onSave: _saveProfile,
                  onSignOut: () async {
                      await _authService.signOut();
                      if (mounted) {
                         // Pop back to root (AuthGate will handle showing login)
                         Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                  },
                  onUploadImage: _pickAndUploadImage,
                ),
    );
  }
}
