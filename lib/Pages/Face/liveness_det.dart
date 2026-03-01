import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:verilabs/Pages/Face/capture.dart';
import 'package:verilabs/Pages/KTP/rechieve.dart';
import 'package:verilabs/Widgets/progress_indicator.dart';

class LivenessDet extends StatefulWidget {
  final String imgPath;

  const LivenessDet({Key? key, required this.imgPath}) : super(key: key);

  @override
  State<LivenessDet> createState() => _LivenessDetState();
}

class _LivenessDetState extends State<LivenessDet> {
  CameraController? _camController;
  FaceDetector? _faceDetector;

  bool _isCamInitialized = false;
  bool _isProcessing = false;
  bool _isScanning = false;
  bool _isLivenessSuccess = false;
  bool _isNavigating = false;
  bool _isTransitioning = false;

  int _currentTaskIndex = 0;
  String _instructionText = "Tekan tombol Pindai untuk mulai";

  final List<String> _tasks = [
    "Silakan Tersenyum",
    "Kedipkan Kedua Mata",
    "Tolehkan Kepala ke kiri",
    "Verifikasi Berhasil!",
  ];

  @override
  void initState() {
    super.initState();
    _initCameraAndDetector();
  }

  Future<void> _initCameraAndDetector() async {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _camController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _camController!.initialize();

      if (mounted && !_isNavigating) {
        setState(() {
          _isCamInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Gagal inisialisasi kamera: $e");
    }
  }

  Future<void> _mulaiPindai() async {
    if (_isScanning ||
        _isLivenessSuccess ||
        _camController == null ||
        _isNavigating)
      return;

    setState(() {
      _isScanning = true;
      _currentTaskIndex = 0;
      _instructionText = _tasks[_currentTaskIndex];
    });

    _camController!.startImageStream(_prosesFrameKamera);
  }

  Future<void> _prosesFrameKamera(CameraImage image) async {
    if (_isProcessing ||
        _isLivenessSuccess ||
        _isNavigating ||
        _isTransitioning)
      return;
    _isProcessing = true;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      const imageRotation = InputImageRotation.rotation270deg;
      final inputImageFormat = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      await _deteksiWajah(inputImage);
    } catch (e) {
      debugPrint("Error processing frame: $e");
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _deteksiWajah(InputImage inputImage) async {
    if (_faceDetector == null || _isNavigating || _isTransitioning) return;
    final faces = await _faceDetector!.processImage(inputImage);

    if (faces.isEmpty) {
      if (mounted &&
          _instructionText != "Wajah tidak terdeteksi!" &&
          !_isNavigating &&
          !_isTransitioning) {
        setState(() {
          _instructionText = "Wajah tidak terdeteksi!";
        });
      }
      return;
    }

    final face = faces.first;

    switch (_currentTaskIndex) {
      case 0:
        if (face.smilingProbability != null && face.smilingProbability! > 0.9) {
          _lanjutTugas();
        } else {
          _updateInstruksi(_tasks[_currentTaskIndex]);
        }
        break;

      case 1:
        if (face.leftEyeOpenProbability != null &&
            face.rightEyeOpenProbability != null) {
          if (face.leftEyeOpenProbability! < 0.4 &&
              face.rightEyeOpenProbability! < 0.4) {
            _lanjutTugas();
          } else {
            _updateInstruksi(_tasks[_currentTaskIndex]);
          }
        }
        break;

      case 2:
        if (face.headEulerAngleY != null) {
          if (face.headEulerAngleY! > 40 || face.headEulerAngleY! < -40) {
            _suksesLiveness();
          } else {
            _updateInstruksi(_tasks[_currentTaskIndex]);
          }
        }
        break;
    }
  }

  void _updateInstruksi(String teks) {
    if (mounted &&
        _instructionText != teks &&
        !_isNavigating &&
        !_isTransitioning) {
      setState(() {
        _instructionText = teks;
      });
    }
  }

  void _lanjutTugas() async {
    if (!mounted || _isNavigating || _isTransitioning) return;

    setState(() {
      _isTransitioning = true;
      _currentTaskIndex++;
      _instructionText = "Bagus! Berikutnya...";
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted && !_isNavigating) {
      setState(() {
        if (_currentTaskIndex < _tasks.length) {
          _instructionText = _tasks[_currentTaskIndex];
        }
        _isTransitioning = false;
      });
    }
  }

  void _suksesLiveness() async {
    if (!mounted || _isNavigating || _isTransitioning) return;

    setState(() {
      _isTransitioning = true;
    });

    if (_camController != null && _camController!.value.isStreamingImages) {
      await _camController!.stopImageStream().catchError((e) {});
    }

    if (mounted && !_isNavigating) {
      setState(() {
        _isLivenessSuccess = true;
        _isScanning = false;
        _instructionText = _tasks.last;
        _isTransitioning = false;
      });
    }
  }

  Future<void> _tutupKameraDanNavigasi(Widget halamanTujuan) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    if (_camController != null && _camController!.value.isStreamingImages) {
      await _camController!.stopImageStream().catchError((e) {});
    }

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
    if (_camController != null) {
      if (_camController!.value.isStreamingImages) {
        _camController!.stopImageStream().catchError((e) {});
      }
      _camController!.dispose();
    }
    _faceDetector?.close();
    super.dispose();
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
            const CustomProgressBar(currStep: 3),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Liveness Detection",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Ikuti gerakan di layar seperti kedip atau geleng pelan. Ini untuk memastikan kamu pengguna nyata",
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
            (!_isCamInitialized ||
                    _camController == null ||
                    _camController!.value.previewSize == null)
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : Builder(
                    builder: (context) {
                      final previewSize = _camController!.value.previewSize!;

                      return Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isLivenessSuccess
                                ? Colors.green
                                : Colors.teal,
                            width: 4.0,
                          ),
                        ),
                        child: ClipOval(
                          child: Stack(
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
                              if (_isLivenessSuccess)
                                Container(color: Colors.green.withOpacity(0.3)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isLivenessSuccess
                    ? Colors.green.shade50
                    : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isLivenessSuccess
                      ? Colors.green
                      : Colors.teal.shade200,
                ),
              ),
              child: Text(
                _instructionText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isLivenessSuccess
                      ? Colors.green.shade700
                      : Colors.teal.shade700,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _tutupKameraDanNavigasi(
                        Rechieve(imgPath: widget.imgPath),
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
                          "Kembali",
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
                    onTap: () {
                      if (_isLivenessSuccess) {
                        _tutupKameraDanNavigasi(const TakeSelfie());
                      } else if (!_isScanning) {
                        _mulaiPindai();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isScanning && !_isLivenessSuccess
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
                            _isLivenessSuccess
                                ? "Lanjut"
                                : (_isScanning ? "Memindai..." : "Pindai"),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isLivenessSuccess
                                ? Icons.check_circle
                                : Icons.document_scanner_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
