import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang  = state.language;
    final user  = state.user!;

    final T = {
      'ru': {'settings': 'Настройки', 'language': 'Язык', 'notifications': 'Push-уведомления', 'on': 'Вкл', 'off': 'Выкл', 'logout': 'Выйти', 'attended': 'Посещено', 'saved': 'Избранных', 'reviews': 'Отзывов', 'history': 'История посещений'},
      'kz': {'settings': 'Баптаулар', 'language': 'Тіл', 'notifications': 'Push-хабарламалар', 'on': 'Қосу', 'off': 'Өшіру', 'logout': 'Шығу', 'attended': 'Барды', 'saved': 'Таңдаулы', 'reviews': 'Пікір', 'history': 'Қатысу тарихы'},
      'en': {'settings': 'Settings', 'language': 'Language', 'notifications': 'Push Notifications', 'on': 'On', 'off': 'Off', 'logout': 'Log Out', 'attended': 'Attended', 'saved': 'Saved', 'reviews': 'Reviews', 'history': 'Attended Events'},
    }[lang]!;

    final badges = user.role == 'student'
        ? ['🏆 Active Student', '⭐ Top Attendee', '🎓 AITU Member']
        : ['🎪 Organizer Pro', '📊 Analytics Master'];

    final attended = [
      {'emoji': '🎤', 'title': 'TEDx AITU 2024',            'date': 'Nov 2024'},
      {'emoji': '💻', 'title': 'Hackathon Digital KZ 2025',  'date': 'Feb 2025'},
      {'emoji': '🎨', 'title': 'Art Market AITU',            'date': 'Mar 2025'},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero gradient
          Container(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              children: [
                Container(
                  width: 76, height: 76,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)),
                  child: Center(child: Text(user.initials, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(height: 12),
                Text(user.name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text(user.email, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 4),
                Text('${user.role == 'student' ? (lang == 'ru' ? 'Студент' : lang == 'kz' ? 'Студент' : 'Student') : (lang == 'ru' ? 'Организатор' : lang == 'kz' ? 'Ұйымдастырушы' : 'Organizer')} · Astana IT University',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                  children: badges.map((b) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(b, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  )).toList(),
                ),
              ],
            ),
          ),

          // Stats
          Container(
            color: AppColors.card,
            child: Row(
              children: [
                _statBox('${attended.length + state.registrations.length}', T['attended']!),
                _divider(),
                _statBox('${state.favorites.length}', T['saved']!),
                _divider(),
                _statBox('${state.userRatings.length}', T['reviews']!),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Attended history
          if (user.role == 'student') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(alignment: Alignment.centerLeft, child: Text(T['history']!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6))),
            ),
            Container(
              color: AppColors.card,
              child: Column(
                children: attended.map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
                  child: Row(
                    children: [
                      Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(a['emoji']!, style: const TextStyle(fontSize: 22)))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['title']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                            Text(a['date']!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Settings
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text(T['settings']!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6))),
          ),
          Container(
            color: AppColors.card,
            child: Column(
              children: [
                // Language
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(T['language']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text))),
                      Container(
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: ['ru', 'kz', 'en'].map((l) {
                            final active = state.language == l;
                            return GestureDetector(
                              onTap: () => state.setLanguage(l),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                                child: Text(l.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.muted)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0.5, color: AppColors.border),

                // Notifications
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(T['notifications']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text))),
                      GestureDetector(
                        onTap: () => setState(() => _notificationsOn = !_notificationsOn),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: _notificationsOn ? AppColors.secondary : Colors.grey.shade300, borderRadius: BorderRadius.circular(20)),
                          child: Text(_notificationsOn ? T['on']! : T['off']!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0.5, color: AppColors.border),

                // Logout
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(T['logout']!, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      content: Text(lang == 'ru' ? 'Вы уверены, что хотите выйти?' : lang == 'kz' ? 'Шығуды қалайсыз ба?' : 'Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(lang == 'ru' ? 'Отмена' : lang == 'kz' ? 'Жоқ' : 'Cancel'),
                        ),
                        TextButton(
                          onPressed: () { Navigator.pop(context); state.logout(); },
                          child: Text(lang == 'ru' ? 'Выйти' : lang == 'kz' ? 'Иә' : 'Log out', style: const TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                        const SizedBox(width: 12),
                        Text(T['logout']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.danger)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _statBox(String val, String label) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(children: [
        Text(val, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted)),
      ]),
    ),
  );

  Widget _divider() => const SizedBox(height: 40, child: VerticalDivider(width: 0.5, color: AppColors.border));
}
