import 'package:flutter/material.dart';
import 'package:sample/src/providers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: 'appuser@alhamood.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '123456',
  );
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();

  // Auth controller
  final AuthController _authController = AuthController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    print('signinbutton pressed');
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      print('validated');
      _authController.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
              SizedBox(height: 40),
              Text(
                "Welcome back!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Let's login for explore continues",
                style: TextStyle(fontSize: 16, color: Color(0xFF718096)),
              ),
              SizedBox(height: 32),
              // Email Field
              Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF4A9B8E)),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or phone number';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'enter your email',
                      hintStyle: TextStyle(color: Color(0xFF718096)),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Color(0xFF4A9B8E),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Password Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF4A9B8E)),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'password',
                    hintStyle: TextStyle(color: Color(0xFF718096)),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Color(0xFF4A9B8E),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Color(0xFF718096),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(color: Color(0xFF718096), fontSize: 14),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Sign In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A9B8E),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
