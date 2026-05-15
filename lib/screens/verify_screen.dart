import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snack.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  const VerifyScreen({super.key, required this.email});
  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final List<TextEditingController> _ctrls =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) {
      showSnack(context, _t('enterAllDigits'));
      return;
    }
    setState(() => _verifying = true);
    try {
      final result = await ApiService.verifyEmail(widget.email, _code);
      final state = context.read<AppState>();
      final token = result['token'] as String;
      final userMap = result['user'] as Map<String, dynamic>;
      state.setToken(token);
      state.login(
        userMap['email'] as String,
        userMap['name'] as String,
        userMap['role'] as String,
        userId: (userMap['_id'] ?? userMap['id'])?.toString() ?? '',
      );
      // Загружаем данные
      await state.refreshMyRegistrations();
      final eventsData = await ApiService.getEvents(token);
      final parsed = eventsData
          .whereType<Map<String, dynamic>>()
          .map(EventModel.fromJson)
          .toList();
      state.setEvents(parsed);
      final favs = await ApiService.getFavorites(token);
      state.setFavorites(favs);
      await state.refreshNotifications();
    } catch (e) {
      if (mounted) {
        showSnack(context, e.toString().replaceFirst('Exception: ', ''));
        // Очищаем поля при ошибке
        for (final c in _ctrls) c.clear();
        _nodes[0].requestFocus();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    setState(() => _resending = true);
    try {
      await ApiService.resendCode(widget.email);
      if (mounted) {
        showSnack(context, _t('codeSent'));
        _startTimer();
        for (final c in _ctrls) c.clear();
        _nodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String _t(String key) {
    final lang = context.read<AppState>().language;
    const map = <String, Map<String, String>>{
      'title': {'ru': 'Подтверждение email', 'kz': 'Email растау', 'en': 'Email Verification'},
      'subtitle': {'ru': 'Мы отправили 6-значный код на', 'kz': '6 таңбалы код жіберілді', 'en': 'We sent a 6-digit code to'},
      'confirm': {'ru': 'Подтвердить', 'kz': 'Растау', 'en': 'Confirm'},
      'resend': {'ru': 'Отправить повторно', 'kz': 'Қайта жіберу', 'en': 'Resend code'},
      'resendIn': {'ru': 'Повторно через', 'kz': 'Қайта жіберу', 'en': 'Resend in'},
      'seconds': {'ru': 'сек', 'kz': 'сек', 'en': 's'},
      'codeSent': {'ru': 'Код отправлен повторно', 'kz': 'Код қайта жіберілді', 'en': 'Code resent'},
      'enterAllDigits': {'ru': 'Введите все 6 цифр', 'kz': '6 санды енгізіңіз', 'en': 'Enter all 6 digits'},
      'back': {'ru': 'Назад', 'kz': 'Артқа', 'en': 'Back'},
    };
    return map[key]?[lang] ?? map[key]?['ru'] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_t('title'),
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),

            Text(_t('title'),
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 8),
            Text(_t('subtitle'),
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(widget.email,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                textAlign: TextAlign.center),

            const SizedBox(height: 36),

            // Code input boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 46, height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _ctrls[i].text.isNotEmpty
                          ? AppColors.primary
                          : AppColors.border,
                      width: _ctrls[i].text.isNotEmpty ? 2 : 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _ctrls[i],
                    focusNode: _nodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      setState(() {});
                      if (val.isNotEmpty && i < 5) {
                        _nodes[i + 1].requestFocus();
                      }
                      if (val.isEmpty && i > 0) {
                        _nodes[i - 1].requestFocus();
                      }
                      // Автоматически верифицируем когда введены все 6 цифр
                      if (_code.length == 6) _verify();
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Confirm button
            GestureDetector(
              onTap: _verifying ? null : _verify,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _verifying
                      ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(_t('confirm'),
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Resend
            _resending
                ? const CircularProgressIndicator()
                : GestureDetector(
              onTap: _resendSeconds == 0 ? _resend : null,
              child: Text(
                _resendSeconds > 0
                    ? '${_t('resendIn')} $_resendSeconds ${_t('seconds')}'
                    : _t('resend'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _resendSeconds == 0 ? AppColors.primary : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}