import 'package:core/core.dart';
import 'package:flutter/material.dart';

class OrganizationRegistrationScreen extends StatefulWidget {
  const OrganizationRegistrationScreen({super.key});

  @override
  State<OrganizationRegistrationScreen> createState() => _OrganizationRegistrationScreenState();
}

class _OrganizationRegistrationScreenState extends State<OrganizationRegistrationScreen> {
  final _orgNameController = TextEditingController();
  final _branchNameController = TextEditingController(text: 'Main Campus');
  final _orgRepo = OrganizationRepository();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Organization')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Register your Organization',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _orgNameController,
              decoration: const InputDecoration(
                labelText: 'Organization Name',
                hintText: 'e.g. Grace Community Church',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _branchNameController,
              decoration: const InputDecoration(
                labelText: 'Default Branch Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _registerOrganization,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Create Organization'),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerOrganization() async {
    if (_orgNameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _orgRepo.createOrganizationWithBranch(
        orgName: _orgNameController.text.trim(),
        branchName: _branchNameController.text.trim(),
      );
      if (mounted) {
        // Pop back to main, which should now show dashboard (or we can navigate specifically)
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Organization Created Successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
