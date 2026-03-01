import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:verilabs/Pages/KTP/rechieve.dart';
import 'package:image/image.dart' as img;
import 'package:verilabs/Widgets/progress_indicator.dart';

import 'package:verilabs/Services/storage.dart';

class ScanKTP extends StatefulWidget {
  const ScanKTP({Key? key}) : super(key: key);

  @override
  State<ScanKTP> createState() => _ScanKTPState();
}

class _ScanKTPState extends State<ScanKTP> {
  late CameraController _camController;
  bool _isCamInitiallized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        debugPrint("Kamera tidak ditemukan di perangkat ini.");
        return;
      }

      _camController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _camController.initialize();

      if (mounted) {
        setState(() {
          _isCamInitiallized = true;
        });
      }
    } catch (e) {
      debugPrint("Gagal menginisialisasi kamera: $e");
    }
  }

  @override
  void dispose() {
    _camController.dispose();
    super.dispose();
  }

  // crop ktp supaya rapih o>
  Future<String?> _cropImage(String imagePath, double screenWidth) async {
    try {
      final File file = File(imagePath);
      final bytes = await file.readAsBytes();

      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      final double targetRatio = screenWidth / 250.0;

      final int cropWidth = originalImage.width;
      final int cropHeight = (cropWidth / targetRatio).round();

      final int cropY = ((originalImage.height - cropHeight) / 2).round();

      final img.Image croppedImage = img.copyCrop(
        originalImage,
        x: 0,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      final String croppedPath = imagePath.replaceFirst('.jpg', '_cropped.jpg');
      final File croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

      return croppedPath;
    } catch (e) {
      debugPrint("Gagal memotong gambar: $e");
      return null;
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
            children: [
              Column(
                children: [
                  CustomProgressBar(currStep: 2),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Scan E-KTP",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          height: 1.2,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Container(
                    width: 300,
                    height: 300,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: _isCamInitiallized
                        ? ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width,
                                  height: 250,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: MediaQuery.sizeOf(context).width,
                                      height:
                                          MediaQuery.sizeOf(context).width *
                                          _camController.value.aspectRatio,
                                      child: CameraPreview(_camController),
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Image.asset(
                                    'assets/borders/frame_id_card.png',
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  try {
                    if (!_camController.value.isInitialized) {
                      return;
                    }

                    final XFile image = await _camController.takePicture();

                    final double screenWidth = MediaQuery.sizeOf(context).width;
                    final String? croppedImagePath = await _cropImage(
                      image.path,
                      screenWidth,
                    );
                    // test
                    debugPrint(
                      "Gambar berhasil diambil. Lokasi: ${image.path}",
                    );

                    if (context.mounted && croppedImagePath != null) {
                      // save ke storage
                      KycStorage.ktpImgPath = croppedImagePath;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Rechieve(imgPath: croppedImagePath),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Error mengmbil gambar: $e");
                  }
                },
                child: Container(
                  width: MediaQuery.sizeOf(context).width,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF15A24),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Pindai",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.document_scanner_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
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
