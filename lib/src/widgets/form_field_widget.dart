import 'package:flutter/material.dart';

class CustomFormField extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isRequired;

  const CustomFormField({
    super.key,
    required this.title,
    required this.child,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children:
                isRequired
                    ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                    : [],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
