import 'package:flutter/material.dart';
import 'package:ui_kit/src/widgets/organization_registration_auth_screen.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function(String email, String password)? onSignUp;
  final Future<void> Function()? onGoogleSignIn;
  final String title;

  const LoginScreen({
    super.key,
    required this.onLogin,
    this.onSignUp,
    this.onGoogleSignIn,
    this.title = 'Welcome Back',
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _errorMessage;

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp && widget.onSignUp != null) {
        await widget.onSignUp!(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await widget.onLogin(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isSignUp ? 'Create User Account' : widget.title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isSignUp ? 'Create User Account' : 'Sign In'),
              ),
              if (widget.onGoogleSignIn != null && !_isLoading) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    try {
                      await widget.onGoogleSignIn!();
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _errorMessage = e.toString();
                        });
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.login), // Replace with specific Google icon if available/wanted, standard icon for now.
                  label: const Text('Sign in with Google'),
                ),
              ],
              if (_isSignUp) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                OutlinedButton(
                   onPressed: () {
                     setState(() {
                       _isSignUp = false;
                       _errorMessage = null;
                     });
                   },
                   child: const Text('Already have an account? Sign In'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Organization Registration needs the signup callback to create the user first
                    if (widget.onSignUp == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registration not enabled')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrganizationRegistrationAuthScreen(
                          // We pass the signup logic from the implementation layer
                          onSignUp: widget.onSignUp!, 
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.business),
                  label: const Text('Register New Organization'),
                ),
              ] else if (widget.onSignUp != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isSignUp = true;
                            _errorMessage = null;
                          });
                        },
                  child: const Text('New User? Create Account'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
