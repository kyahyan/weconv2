import 'package:core/core.dart';
import 'package:flutter/material.dart';

class OrganizationRegistrationAuthScreen extends StatefulWidget {
  final Function(String email, String password) onSignUp;

  const OrganizationRegistrationAuthScreen({super.key, required this.onSignUp});

  @override
  State<OrganizationRegistrationAuthScreen> createState() => _OrganizationRegistrationAuthScreenState();
}

class _OrganizationRegistrationAuthScreenState extends State<OrganizationRegistrationAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _branchNameController = TextEditingController(text: 'Main Campus');
  final _orgRepo = OrganizationRepository();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _orgNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create User Account first
      try {
        await widget.onSignUp(_emailController.text.trim(), _passwordController.text.trim());
      } catch (e) {
        // If user already exists, try logging them in instead
        if (e.toString().contains('user_already_exists')) {
            // NOTE: We rely on the parent's Login logic effectively, but here we can try to "continue"
            // For now, let's inform the user clearly or handle it. 
            // Better yet: If you own this email, we proceed to org creation?
            // This is tricky without password confirmation. 
            // Let's just catch and rethrow with a clearer message, OR assume we are just stuck.
            
            // Actually, if they just created it 1 minute ago and it failed, they exist.
            // Let's NOT auto-login (security). 
            // Instead, tell them: "Account exists. Please Log In first, then register org."
            // But wait, our flow for "Register Org" is separate.
            
            // Allow "Resume" approach? 
            // Simplest fix:
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account already exists. Please delete it or use a different email.')),
            );
            return;
        }
        rethrow;
      }
      
      // 2. Create Organization
      await _orgRepo.createOrganizationWithBranch(
        orgName: _orgNameController.text.trim(),
        branchName: _branchNameController.text.trim(),
      );

      if (mounted) {
        // Success - Navigate back or show success
        Navigator.pop(context); // Close registration screen
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Organization Submitted! Waiting for Superadmin approval.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Organization')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Create Admin Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            const Divider(height: 40),
            const Text('Organization Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _orgNameController, decoration: const InputDecoration(labelText: 'Organization Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _branchNameController, decoration: const InputDecoration(labelText: 'Default Branch Name', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Register Organization'),
                ),
          ],
        ),
      ),
    );
  }
}
