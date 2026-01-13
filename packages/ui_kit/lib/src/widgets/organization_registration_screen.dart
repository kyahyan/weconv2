import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Register your Organization',
              style: ShadTheme.of(context).textTheme.h3,
            ),
            const SizedBox(height: 24),
            Text('Organization Name', style: ShadTheme.of(context).textTheme.small),
            const SizedBox(height: 8),
            ShadInput(
              controller: _orgNameController,
              placeholder: const Text('e.g. Grace Community Church'),
            ),
            const SizedBox(height: 16),
            Text('Default Branch Name', style: ShadTheme.of(context).textTheme.small),
            const SizedBox(height: 8),
            ShadInput(
              controller: _branchNameController,
              placeholder: const Text('e.g. Main Campus'),
            ),
            const SizedBox(height: 32),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ShadButton(
                  width: double.infinity,
                  onPressed: _registerOrganization,
                  text: const Text('Create Organization'),
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
