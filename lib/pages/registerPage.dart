import 'package:flutter/material.dart';
import 'package:wait_wise/pages/successPage.dart';
import 'package:wait_wise/services/queue_service.dart';

class RegisterPage extends StatefulWidget {
  final String serviceName;

  const RegisterPage({super.key, required this.serviceName});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _kebeleIdController = TextEditingController();
  final _queueService = QueueService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _kebeleIdController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      // Show error message if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate service name
    if (widget.serviceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service name is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Prepare user data - ensure all values are strings
      final userData = <String, dynamic>{
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'kebeleId': _kebeleIdController.text.trim(),
      };

      // Register user and get queue number
      final queueNumber = _queueService.registerUser(widget.serviceName, userData);

      // Ensure queue number is valid
      if (queueNumber <= 0) {
        throw Exception('Failed to get queue number');
      }

      // Navigate to success page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessPage(
              serviceName: widget.serviceName,
              queueNumber: queueNumber,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Show error if something goes wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // Print stack trace for debugging
      print('Registration error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5CC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5CC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Register for ${widget.serviceName}",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildInputField("Full name", _fullNameController, isRequired: true),
              const SizedBox(height: 15),

              _buildInputField("Phone no", _phoneController, isRequired: true),
              const SizedBox(height: 15),

              _buildInputField("Kebele / Id number (optional)", _kebeleIdController, isRequired: false),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _handleRegister,
                  child: const Text(
                    "Register",
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller, {required bool isRequired}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        errorStyle: const TextStyle(color: Colors.red),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }
}
