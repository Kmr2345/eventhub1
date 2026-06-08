import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController controller = MobileScannerController();

  bool _scanned = false;
  bool _loading = false;
  bool _success = false;
  bool _alreadyScanned = false;

  String? _message;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _loading) return;

    final code = capture.barcodes.first.rawValue;

    if (code == null || code.isEmpty) return;

    setState(() {
      _scanned = true;
      _loading = true;
      _message = null;
    });

    final token = context.read<AppState>().token ?? '';

    try {
      await ApiService.markAttended(code, token);

      setState(() {
        _success = true;
        _loading = false;
        _alreadyScanned = false;
      });
    } catch (e) {
      setState(() {
        _success = false;
        _loading = false;

        _alreadyScanned =
            e.toString().contains('409') ||
                e.toString().contains('Already attended');
      });
    }
  }

  void _reset() {
    setState(() {
      _scanned = false;
      _loading = false;
      _message = null;
      _success = false;
      _alreadyScanned = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;

    final T = {
      'ru': {
        'title': 'Сканировать QR',
        'hint': 'Наведите камеру на QR-код студента',
        'success': 'Присутствие отмечено!',
        'error': 'Ошибка — попробуйте снова',
        'alreadyAttended': 'Студент уже отсканирован',
        'scanMore': 'Сканировать ещё',
        'back': 'Назад',
      },
      'kz': {
        'title': 'QR сканерлеу',
        'hint': 'Камераны студенттің QR-кодына бағыттаңыз',
        'success': 'Қатысу белгіленді!',
        'error': 'Қате — қайталап көріңіз',
        'alreadyAttended': 'Студент бұрын сканерленген',
        'scanMore': 'Тағы сканерлеу',
        'back': 'Артқа',
      },
      'en': {
        'title': 'Scan QR',
        'hint': 'Point the camera at the student\'s QR code',
        'success': 'Attendance marked!',
        'error': 'Error — please try again',
        'alreadyAttended': 'Student already scanned',
        'scanMore': 'Scan another',
        'back': 'Go Back',
      },
    }[lang]!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          T['title']!,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.flash_on_rounded,
              color: Colors.white,
            ),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Overlay frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Hint text
          if (!_scanned)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Text(
                T['hint']!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),

          // Result card
          if (_scanned)
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading)
                      const CircularProgressIndicator()
                    else ...[
                      Icon(
                        _success
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: _success
                            ? Colors.green
                            : AppColors.danger,
                        size: 48,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        _success
                            ? T['success']!
                            : _alreadyScanned
                            ? T['alreadyAttended']!
                            : T['error']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _success
                              ? Colors.green
                              : AppColors.danger,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          // Back button
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    T['back']!,
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Scan more button
                          Expanded(
                            child: GestureDetector(
                              onTap: _reset,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryLight,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    T['scanMore']!,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}