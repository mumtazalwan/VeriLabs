import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';

class CustomProgressBar extends StatelessWidget {
  final int currStep;

  const CustomProgressBar({super.key, required this.currStep});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/logos/VeriLabs.png', width: 180),
          SizedBox(height: 22),
          LinearProgressBar(
            maxSteps: 5,
            currentStep: currStep,
            progressColor: const Color(0xFF2A3853),
            borderRadius: BorderRadius.circular(16),
            backgroundColor: const Color(0xFFD9D9D9),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
