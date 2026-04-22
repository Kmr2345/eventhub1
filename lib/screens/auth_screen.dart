import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:eventhub/data/app_state.dart';
import 'package:eventhub/theme/app_theme.dart';
import 'package:eventhub/services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'student';

  final _labels = {
    'ru': {'welcome': 'Добро пожаловать в', 'tagline': 'Все мероприятия кампуса в одном месте', 'email': 'Email', 'password': 'Пароль', 'student': 'Студент', 'organizer': 'Организатор', 'login': 'Войти', 'demo': 'Демо: любой email и пароль'},
    'kz': {'welcome': 'Қош келдіңіз', 'tagline': 'Кампустың барлық іс-шаралары бір жерде', 'email': 'Email', 'password': 'Құпия сөз', 'student': 'Студент', 'organizer': 'Ұйымдастырушы', 'login': 'Кіру', 'demo': 'Демо: кез келген email және пароль'},
    'en': {'welcome': 'Welcome to', 'tagline': 'All campus events in one place', 'email': 'Email', 'password': 'Password', 'student': 'Student', 'organizer': 'Organizer', 'login': 'Log In', 'demo': 'Demo: use any email & password'},
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
                              style: GoogleFonts.dmSans(
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
                Text(t['welcome']!, style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 4),
                Text('EventHub', style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Astana IT University', style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 4),
                Text(t['tagline']!, style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.center),
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
                                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.muted),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildField(t['email']!, _emailCtrl, 'email@aitu.edu.kz', false),
                      const SizedBox(height: 14),
                      _buildField(t['password']!, _passwordCtrl, '••••••••', true),
                      const SizedBox(height: 20),

                      // Login button
                      GestureDetector(
                        onTap: () async {
                          final email = _emailCtrl.text;
                          final password = _passwordCtrl.text;

                          try {
                            final result = await ApiService.login(email, password);

                            final token = result['token'] as String;
                            final user = result['user'] as Map<String, dynamic>;

                            state.setToken(token);
                            state.login(
                              user['email'] as String,
                              user['name'] as String,
                              user['role'] as String,
                            );

                          } catch (e) {
                            print("Login error: $e");
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(t['login']!, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(t['demo']!, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
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
      Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
    ],
  );

  Widget _buildField(String label, TextEditingController ctrl, String hint, bool obscure) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: AppColors.muted),
          filled: true, fillColor: AppColors.bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    ],
  );
}
