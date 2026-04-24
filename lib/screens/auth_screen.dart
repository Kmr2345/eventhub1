import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:eventhub/data/app_state.dart';
import 'package:eventhub/localization/error_texts.dart';
import 'package:eventhub/localization/messages.dart';
import 'package:eventhub/models/event_model.dart';
import 'package:eventhub/theme/app_theme.dart';
import 'package:eventhub/services/api_service.dart';
import 'package:eventhub/widgets/app_snack.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'student';
  bool isRegister = false;
  bool _emailInvalid = false;
  bool _passwordInvalid = false;

  final _labels = {
    'ru': {
      'welcome': 'Добро пожаловать в',
      'tagline': 'Все мероприятия кампуса в одном месте',
      'name': 'Имя',
      'nameHint': 'Ваше имя',
      'email': 'Email',
      'password': 'Пароль',
      'student': 'Студент',
      'organizer': 'Организатор',
      'login': 'Войти',
      'register': 'Зарегистрироваться',
      'createAccount': 'Создать аккаунт',
      'signupPrompt': 'Нет аккаунта? ',
      'signupCta': 'Зарегистрируйтесь',
      'signinPrompt': 'Уже есть аккаунт? ',
      'signinCta': 'Войти',
      'registerSuccess': 'Регистрация успешна',
    },
    'kz': {
      'welcome': 'Қош келдіңіз',
      'tagline': 'Кампустың барлық іс-шаралары бір жерде',
      'name': 'Аты-жөні',
      'nameHint': 'Атыңыз',
      'email': 'Email',
      'password': 'Құпия сөз',
      'student': 'Студент',
      'organizer': 'Ұйымдастырушы',
      'login': 'Кіру',
      'register': 'Тіркелу',
      'createAccount': 'Аккаунт ашу',
      'signupPrompt': 'Аккаунтыңыз жоқ па? ',
      'signupCta': 'Тіркеліңіз',
      'signinPrompt': 'Аккаунтыңыз бар ма? ',
      'signinCta': 'Кіру',
      'registerSuccess': 'Тіркелу сәтті өтті',
    },
    'en': {
      'welcome': 'Welcome to',
      'tagline': 'All campus events in one place',
      'name': 'Name',
      'nameHint': 'Your name',
      'email': 'Email',
      'password': 'Password',
      'student': 'Student',
      'organizer': 'Organizer',
      'login': 'Log In',
      'register': 'Sign up',
      'createAccount': 'Create account',
      'signupPrompt': 'Don\'t have an account? ',
      'signupCta': 'Sign up',
      'signinPrompt': 'Already have an account? ',
      'signinCta': 'Log in',
      'registerSuccess': 'Registration successful',
    },
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = _labels[state.language]!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE), Color(0xFFF7F6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4, 0.75],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Language switcher
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['ru', 'kz', 'en'].map((l) {
                        final active = state.language == l;
                        return GestureDetector(
                          onTap: () => state.setLanguage(l),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: active ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              l.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: active ? AppColors.primary : Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Hero
                const SizedBox(height: 20),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: const Center(child: Text('🎯', style: TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 16),
                Text(t['welcome']!, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 4),
                Text('EventHub', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Astana IT University', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 4),
                Text(t['tagline']!, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.center),
                const SizedBox(height: 20),

                // Features row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _featureItem('📅', state.language == 'ru' ? 'Находите события' : state.language == 'kz' ? 'Іс-шараларды табыңыз' : 'Discover Events'),
                    const SizedBox(width: 20),
                    _featureItem('📝', state.language == 'ru' ? 'Регистрация' : state.language == 'kz' ? 'Тіркелу' : 'Registration'),
                    const SizedBox(width: 20),
                    _featureItem('⭐', state.language == 'ru' ? 'Оценивайте' : state.language == 'kz' ? 'Бағалаңыз' : 'Rate & Review'),
                  ],
                ),
                const SizedBox(height: 28),

                // Form card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 8))],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Role selector
                      Container(
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: ['student', 'organizer'].map((r) {
                            final active = _role == r;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _role = r),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    color: active ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      r == 'student' ? t['student']! : t['organizer']!,
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.muted),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (isRegister) ...[
                        _buildField(t['name']!, _nameCtrl, t['nameHint']!, false),
                        const SizedBox(height: 14),
                      ],
                      _buildField(t['email']!, _emailCtrl, 'email@aitu.edu.kz', false, invalid: _emailInvalid),
                      const SizedBox(height: 14),
                      _buildField(t['password']!, _passwordCtrl, '••••••••', true, invalid: _passwordInvalid),
                      const SizedBox(height: 20),

                      // Primary action button
                      GestureDetector(
                        onTap: () async {
                          final lang = context.read<AppState>().language;
                          final email = _emailCtrl.text.trim();
                          final password = _passwordCtrl.text.trim();

                          if (_emailInvalid || _passwordInvalid) {
                            setState(() {
                              _emailInvalid = false;
                              _passwordInvalid = false;
                            });
                          }

                          if (email.isEmpty) {
                            if (!mounted) return;
                            setState(() => _emailInvalid = true);
                            showSnack(context, getError("emptyEmail", lang), isError: true);
                            return;
                          }
                          if (password.isEmpty) {
                            if (!mounted) return;
                            setState(() => _passwordInvalid = true);
                            showSnack(context, getError("emptyPassword", lang), isError: true);
                            return;
                          }
                          if (!isValidEmail(email)) {
                            if (!mounted) return;
                            setState(() => _emailInvalid = true);
                            showSnack(context, getError("invalidEmail", lang), isError: true);
                            return;
                          }
                          if (isRegister && !isValidPassword(password)) {
                            if (!mounted) return;
                            setState(() => _passwordInvalid = true);
                            showSnack(context, getError("weakPassword", lang), isError: true);
                            return;
                          }

                          try {
                            if (!isRegister) {
                              print("LOGIN START");
                              print(email);
                              final result = await ApiService.login(email, password);
                              print("RESPONSE: $result");

                              final token = result['token']?.toString();
                              final userRaw = result['user'];

                              if (token == null || token.isEmpty || userRaw is! Map) {
                                throw Exception('Invalid response: token/user missing');
                              }
                              final user = userRaw.cast<String, dynamic>();
                              final backendRole = user['role']?.toString();
                              if (backendRole != _role) {
                                if (!mounted) return;
                                showSnack(context, getError("wrongRole", lang), isError: true);
                                return;
                              }

                              state.setToken(token);
                              state.login(
                                user['email'] as String,
                                user['name'] as String,
                                user['role'] as String,
                              );
                              // Load registrations so event list cards show registered badge.
                              await state.refreshMyRegistrations();
                              final events = await ApiService.getEvents(token);
                              final parsed = events
                                  .whereType<Map<String, dynamic>>()
                                  .map(EventModel.fromJson)
                                  .toList();
                              state.setEvents(parsed);
                              final favs = await ApiService.getFavorites(token);
                              state.setFavorites(favs);
                              await state.refreshNotifications();
                            } else {
                              final name = _nameCtrl.text.trim();
                              if (name.isEmpty) {
                                throw Exception(t['nameHint']!);
                              }

                              final result = await ApiService.register(name, email, password, _role);
                              print("RESPONSE: $result");

                              if (!mounted) return;
                              showSnack(context, getMessage("registerSuccess", lang));
                              setState(() => isRegister = false);
                              await state.refreshMyRegistrations();
                            }

                          } catch (e) {
                            print("LOGIN ERROR: ${e.toString()}");
                            if (!mounted) return;
                            final raw = e.toString();
                            String message = getError("serverError", lang);

                            if (raw.contains("User not found")) {
                              message = getError("userNotFound", lang);
                            } else if (raw.contains("User already exists")) {
                              message = getError("userExists", lang);
                            } else if (raw.contains("Invalid credentials")) {
                              message = getError("wrongPassword", lang);
                            } else if (raw.contains("SocketException")) {
                              message = getError("networkError", lang);
                            }

                            showSnack(context, message, isError: true);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              isRegister ? t['createAccount']! : t['login']!,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() => isRegister = !isRegister),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                              children: [
                                TextSpan(text: isRegister ? t['signinPrompt']! : t['signupPrompt']!),
                                TextSpan(
                                  text: isRegister ? t['signinCta']! : t['signupCta']!,
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureItem(String emoji, String label) => Column(
    children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
      ),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
    ],
  );

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint,
    bool obscure, {
    bool invalid = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.muted),
          filled: true, fillColor: AppColors.bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: invalid ? AppColors.danger : AppColors.border, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: invalid ? AppColors.danger : AppColors.border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    ],
  );

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
