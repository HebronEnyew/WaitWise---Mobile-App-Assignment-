import 'package:flutter/material.dart';
import 'package:wait_wise/pages/successPage.dart';
import 'package:wait_wise/services/supabase_service.dart';
import 'package:wait_wise/utils/phone_validator.dart';

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

  String _mapServiceName(String displayName) {
    final mapping = {
      "New Id card": "newId",
      "Renew Id card": "renewID",
      "Tax payment": "taxPayment",
      "Birth certificate": "birthCertificate",
    };
    return mapping[displayName] ?? displayName.toLowerCase();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _kebeleIdController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      final userData = <String, dynamic>{
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'kebeleId': _kebeleIdController.text.trim(),
      };

      final dbServiceName = _mapServiceName(widget.serviceName);
      final normalizedPhone = PhoneValidator.normalizePhone(
        userData['phone'] ?? '',
      );

      try {
        final serviceNumber = await SupabaseService.instance.insertUser(
          name: userData['fullName'] ?? '',
          phone: normalizedPhone,
          governmentId: userData['kebeleId'],
          serviceName: dbServiceName,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SuccessPage(
                serviceName: widget.serviceName,
                queueNumber: serviceNumber,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
              _buildInputField(
                "Full name",
                _fullNameController,
                isRequired: true,
              ),
              const SizedBox(height: 15),

              _buildPhoneField(),
              const SizedBox(height: 15),

              _buildInputField(
                "Kebele / Id number (optional)",
                _kebeleIdController,
                isRequired: false,
              ),
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

  Widget _buildInputField(
    String hint,
    TextEditingController controller, {
    required bool isRequired,
  }) {
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
              
              if (hint.toLowerCase().contains('full name')) {
                final v = value.trim();
                if (RegExp(r'\d').hasMatch(v)) {
                  return 'Name cannot contain numbers';
                }
                if (v.length < 2) {
                  return 'Please enter a valid name';
                }
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: "Phone no (09XXXXXXXX or +2519XXXXXXXX)",
        filled: true,
        fillColor: Colors.white,
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Phone number is required';
        }
        if (!PhoneValidator.isValidEthiopianPhone(value.trim())) {
          return PhoneValidator.getErrorMessage();
        }
        return null;
      },
    );
  }
}
