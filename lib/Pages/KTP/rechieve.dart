import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:verilabs/Pages/Face/liveness_det.dart';
import 'package:verilabs/Pages/KTP/scan.dart';
import 'package:verilabs/Services/Models/KTP.dart';
import 'package:verilabs/Widgets/progress_indicator.dart';

import '../../Services/vpn.dart';
import 'package:http/http.dart' as http;

class Rechieve extends StatefulWidget {
  final String imgPath;

  const Rechieve({Key? key, required this.imgPath}) : super(key: key);

  @override
  State<Rechieve> createState() => _RechieveState();
}

class _RechieveState extends State<Rechieve> {
  String _nik = "Sedang memproses...";
  bool _isProcessing = true;
  KTP? _dataKtp;

  @override
  void initState() {
    super.initState();
    _jalankanOCR();
  }

  Future<void> _jalankanOCR() async {
    try {
      final inputImage = InputImage.fromFilePath(widget.imgPath);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String rawText = recognizedText.text;
      String tempNik = "Tidak ditemukan";

      String cleanNikText = rawText
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll('O', '0')
          .replaceAll('o', '0')
          .replaceAll('D', '0')
          .replaceAll('I', '1')
          .replaceAll('i', '1')
          .replaceAll('l', '1')
          .replaceAll('S', '5')
          .replaceAll('s', '5')
          .replaceAll('b', '6')
          .replaceAll('B', '8');

      RegExp nikRegex = RegExp(r'\d{16}');
      Match? match = nikRegex.firstMatch(cleanNikText);
      if (match != null) tempNik = match.group(0)!;

      if (mounted) {
        setState(() {
          _nik = tempNik;
        });

        await fetchDetailKTP();
      }

      textRecognizer.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _nik = "Gagal memproses";
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> fetchDetailKTP() async {
    if (_nik == "Sedang memproses..." ||
        _nik == "Tidak ditemukan" ||
        _nik == "Gagal memproses") {
      debugPrint("NIK tidak valid, membatalkan pemanggilan API.");
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://vl-service-nine.vercel.app/v1/kyc/verify-nik'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nik': _nik}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _dataKtp = KTP.fromJson(responseData);
            _isProcessing = false;
          });
        }
      } else {
        debugPrint("API Error: HTTP ${response.statusCode} - ${response.body}");
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      debugPrint("Gagal memanggil API: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  CustomProgressBar(currStep: 2),
                  SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        child: SizedBox(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(widget.imgPath),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: CircularProgressIndicator(color: Colors.teal),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Nomor Induk Kependudukan (NIK)",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: MediaQuery.sizeOf(context).width,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD9D9D9),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                _nik,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  height: 1.2,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nama",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(),
                            SizedBox(height: 8),
                            Container(
                              width: MediaQuery.sizeOf(context).width,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD9D9D9),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                _dataKtp?.nama ?? "-",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  height: 1.2,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tempat Tanggal Lahir",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: MediaQuery.sizeOf(context).width,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD9D9D9),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                _dataKtp?.tempatLahir ?? "-",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  height: 1.2,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => ScanKTP()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Text(
                            "Ulang",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        bool isVpnDetected = await isUsingVPN();

                        if (isVpnDetected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("VPN Terdeteksi!"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LivenessDet(imgPath: widget.imgPath),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF15A24),
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Text(
                            "Lanjut",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
