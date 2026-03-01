import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:verilabs/Pages/onBoarding.dart';
import 'package:verilabs/Widgets/progress_indicator.dart';

class FinishVerification extends StatelessWidget {
  const FinishVerification({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          top: 60,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          children: [
            const CustomProgressBar(currStep: 5),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Selesai",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Verifikasi kamu diproses! Pantau statusnya di dashboard PayLabs ya",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    height: 1.2,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Lottie.asset(
                'assets/icons/finishJet.json',
                width: MediaQuery.sizeOf(context).width * 0.75,
                repeat: true,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => Onboarding()),
                );
              },
              child: Container(
                width: MediaQuery.sizeOf(context).width,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF15A24),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: const Center(
                  child: Text(
                    "Kembali ke Dashboard",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
