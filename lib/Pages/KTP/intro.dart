import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:verilabs/Pages/KTP/scan.dart';
import 'package:verilabs/Widgets/progress_indicator.dart';

class ScanKTPIntro extends StatelessWidget {
  const ScanKTPIntro({Key? key}) : super(key: key);

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
            const CustomProgressBar(currStep: 1),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Scan E-KTP",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Posisikan KTP sesuai garis panduan sampai semua sudut terbaca jelas. Ini biar data kamu terambil sempurna dan verifikasi cepat diproses",
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
                'assets/icons/ktpIntro.json',
                width: MediaQuery.sizeOf(context).width * 0.75,
                repeat: true,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => ScanKTP()),
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
                    "Mulai",
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
