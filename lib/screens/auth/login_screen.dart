import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../services/credentials_service.dart';
import '../../controllers/employee_controller.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import 'package:hr_demo/providers/api_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // Load saved credentials if Remember Me was enabled
  void _loadSavedCredentials() {
    final savedCreds = CredentialsService.instance.getSavedCredentials();
    if (savedCreds != null) {
      _employeeIdController.text = savedCreds['employeeId'] ?? '';
      _passwordController.text = savedCreds['password'] ?? '';
      _rememberMe = true;
    }
  }

  Future<void> _login() async {
    if (_employeeIdController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Employee ID';
      });
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    // Check internet connection
    final hasInternet =
        await CredentialsService.instance.hasInternetConnection();
    if (!hasInternet) {
      setState(() {
        _errorMessage = 'No internet connection. Please check your connection.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isValid = await hrApiProvider.api.login(
        _employeeIdController.text.trim(),
        _passwordController.text.trim(),
      );

      if (isValid) {
        print("True,$isValid");
        // Save credentials if Remember Me is checked
        await CredentialsService.instance.saveCredentials(
          _employeeIdController.text.trim(),
          _passwordController.text.trim(),
          _rememberMe,
        );

        Get.offAllNamed(AppRoutes.timeTracker);
      } else {
        setState(() {
          _errorMessage = 'Invalid Employee ID or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/logo_word.png",
                  height: 70,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                /*
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/images/geckotech_logo.png",
                      fit: BoxFit.contain,
                      height: 80,
                    ),
                  ),
                ),
                */

                const SizedBox(height: 40),

                // Employee ID field
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _employeeIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Employee ID",
                      border: InputBorder.none,
                      hintText: "Enter your Employee ID",
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Password field
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: InputBorder.none,
                      hintText: "Pass",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Remember Me checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Text(
                      'Remember me',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),

                const SizedBox(height: 24),

                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: AppTheme.primaryButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Log In"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
