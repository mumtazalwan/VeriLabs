import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:verilabs/Pages/finish.dart';
import 'package:verilabs/Widgets/progress_indicator.dart';
import 'package:verilabs/Services/storage.dart';

class TakeSelfie extends StatefulWidget {
  const TakeSelfie({Key? key}) : super(key: key);

  @override
  State<TakeSelfie> createState() => _TakeSelfieState();
}

class _TakeSelfieState extends State<TakeSelfie> {
  CameraController? _camController;
  bool _isCamInitialized = false;
  bool _isProcessing = false;
  bool _isNavigating = false;
  String? _savedImagePath;

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

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _camController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _camController!.initialize();

      if (mounted && !_isNavigating) {
        setState(() {
          _isCamInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Gagal menginisialisasi kamera: $e");
    }
  }

  Future<void> _tutupKameraDanNavigasi(Widget halamanTujuan) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    await _camController?.dispose();
    _camController = null;

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => halamanTujuan),
    );
  }

  @override
  void dispose() {
    _isNavigating = true;
    _camController?.dispose();
    super.dispose();
  }

  Future<String?> _cropSquareImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      final bytes = await file.readAsBytes();

      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      int size = originalImage.width < originalImage.height
          ? originalImage.width
          : originalImage.height;

      int x = (originalImage.width - size) ~/ 2;
      int y = (originalImage.height - size) ~/ 2;

      final img.Image croppedImage = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      final String croppedPath = imagePath.replaceFirst(
        '.jpg',
        '_face_cropped.jpg',
      );
      final File croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

      return croppedPath;
    } catch (e) {
      debugPrint("Gagal memotong gambar: $e");
      return null;
    }
  }

  Future<Position?> _getUserLoc() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Error: GPS perangkat tidak aktif.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Error: Izin lokasi ditolak oleh pengguna.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Error: Izin lokasi ditolak permanen.');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (position.isMocked) {
        debugPrint("Peringatan: Terdeteksi penggunaan GPS Palsu!");
      }

      return position;
    } catch (e) {
      debugPrint("Error mengambil lokasi: $e");
      return null;
    }
  }

  Future<bool> _pushDataToApi() async {
    final ktpPath = KycStorage.ktpImgPath;
    final selfiePath = KycStorage.selfieImgPath;
    final lat = KycStorage.latitude;
    final lng = KycStorage.longitude;

    if (ktpPath == null || selfiePath == null || lat == null || lng == null) {
      debugPrint("Gagal: Data tidak lengkap!");
      return false;
    }

    File fileKtp = File(ktpPath);
    File fileSelfie = File(selfiePath);

    if (!fileKtp.existsSync() || !fileSelfie.existsSync()) {
      debugPrint("Gagal: File fisik gambar tidak ditemukan!");
      return false;
    }

    try {
      var uri = Uri.parse(
        'https://vl-service-nine.vercel.app/v1/kyc/verify-ktp',
      );
      var request = http.MultipartRequest('POST', uri);

      request.fields['lat'] = lat.toString();
      request.fields['lng'] = lng.toString();

      request.files.add(
        await http.MultipartFile.fromPath('file_ktp', fileKtp.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file_selfie', fileSelfie.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Sukses terkirim! Respons Server: ${response.body}");
        return true;
      } else {
        debugPrint("Gagal! Status: ${response.statusCode}");
        debugPrint("Pesan Error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error jaringan saat mengirim ke API: $e");
      return false;
    }
  }

  void _retakePhoto() async {
    if (mounted && !_isNavigating) {
      setState(() {
        _savedImagePath = null;
      });

      if (_camController != null) {
        try {
          await _camController!.resumePreview();
        } catch (e) {
          debugPrint("Gagal resume kamera: $e");
        }
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
        child: Column(
          children: [
            const CustomProgressBar(currStep: 4),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _savedImagePath == null
                      ? "Ambil Foto Wajah"
                      : "Cek Foto Wajah",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _savedImagePath == null
                      ? "Posisikan wajah Anda di dalam lingkaran. Pastikan pencahayaan cukup terang dan wajah terlihat jelas tanpa masker atau kacamata gelap."
                      : "Pastikan foto wajah Anda terlihat jelas, terang, dan tidak buram sebelum mengirimkannya.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    height: 1.4,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _savedImagePath != null ? Colors.green : Colors.teal,
                  width: 4.0,
                ),
              ),
              child: ClipOval(
                child: _savedImagePath != null
                    ? Image.file(
                        File(_savedImagePath!),
                        fit: BoxFit.cover,
                        width: 320,
                        height: 320,
                      )
                    : (!_isCamInitialized ||
                          _camController == null ||
                          _camController!.value.previewSize == null)
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF15A24),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final previewSize =
                              _camController!.value.previewSize!;
                          return Stack(
                            alignment: Alignment.center,
                            fit: StackFit.expand,
                            children: [
                              FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: previewSize.height,
                                  height: previewSize.width,
                                  child: CameraPreview(_camController!),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Image.asset(
                                  'assets/borders/frame_face.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const Spacer(),
            _savedImagePath != null
                ? Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _retakePhoto,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 2,
                              ),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Foto Ulang",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
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
                            if (_isNavigating || _isProcessing) return;

                            setState(() {
                              _isProcessing = true;
                            });

                            KycStorage.selfieImgPath = _savedImagePath;

                            Position? location = await _getUserLoc();

                            if (location == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Gagal mengambil lokasi GPS. Pastikan izin diberikan.",
                                    ),
                                  ),
                                );
                                setState(() => _isProcessing = false);
                              }
                              return;
                            }

                            KycStorage.latitude = location.latitude;
                            KycStorage.longitude = location.longitude;

                            bool isSuccess = await _pushDataToApi();

                            if (mounted && isSuccess) {
                              KycStorage.clearData();
                              _tutupKameraDanNavigasi(
                                const FinishVerification(),
                              );
                            } else {
                              if (mounted) {
                                setState(() => _isProcessing = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Gagal memproses verifikasi. Silakan coba lagi.",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF15A24),
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isProcessing
                                      ? "Memproses..."
                                      : "Gunakan Foto",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isProcessing
                                      ? Icons.hourglass_empty
                                      : Icons.cloud_upload_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () async {
                      if (_isProcessing ||
                          _isNavigating ||
                          _camController == null ||
                          !_camController!.value.isInitialized) {
                        return;
                      }

                      setState(() {
                        _isProcessing = true;
                      });

                      try {
                        final XFile image = await _camController!.takePicture();
                        await _camController!.pausePreview();

                        final String? croppedImagePath = await _cropSquareImage(
                          image.path,
                        );

                        if (mounted &&
                            croppedImagePath != null &&
                            !_isNavigating) {
                          setState(() {
                            _savedImagePath = croppedImagePath;
                          });
                        }
                      } catch (e) {
                        debugPrint("Error mengambil gambar: $e");
                        _camController?.resumePreview();
                      } finally {
                        if (mounted && !_isNavigating) {
                          setState(() {
                            _isProcessing = false;
                          });
                        }
                      }
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isProcessing
                            ? Colors.grey
                            : const Color(0xFFF15A24),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isProcessing ? "Memproses..." : "Ambil Foto",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isProcessing
                                ? Icons.hourglass_empty
                                : Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
