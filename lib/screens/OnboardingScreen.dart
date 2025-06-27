// lib/widgets/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:musico/services/UserOnboardingService%20.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const OnboardingScreen({super.key, required this.onOnboardingComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final UserOnboardingService _onboardingService = UserOnboardingService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final key = _keyController.text.trim();

    if (name.isEmpty || key.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both your name and key.';
        _isLoading = false;
      });
      return;
    }

    try {
      await _onboardingService.completeOnboarding(name, key);
      widget.onOnboardingComplete(); // Notify parent that onboarding is complete
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define colors consistent with LandingPage for a cohesive look
    const Color primaryColor = Color.fromARGB(255, 240, 216, 31);
    const Color textColor = Color(0xFFE0E0E0);
    const Color cardColor = Color(0xFF282846);

    return Scaffold(
      backgroundColor: Colors.black, // Consistent dark background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Let\'s get you set up to enjoy your music.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 48),
              _buildTextField(
                controller: _nameController,
                labelText: 'Your Name',
                icon: Icons.person,
                textColor: textColor,
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _keyController,
                labelText: 'Your Secret Key',
                icon: Icons.vpn_key,
                isObscureText: true,
                textColor: textColor,
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black, // Dark spinner for contrast
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Text color for button
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isObscureText = false,
    required Color textColor,
    required Color cardColor,
    required Color primaryColor,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscureText,
      style: TextStyle(color: textColor, fontSize: 18),
      cursorColor: primaryColor,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.8)),
        filled: true,
        fillColor: cardColor.withOpacity(0.7),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cardColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }
}