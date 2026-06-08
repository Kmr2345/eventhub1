import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final state = context.read<AppState>();
      final t = state.token;
      if (t == null || t.isEmpty) return;
      await state.refreshMyRegistrations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final user = state.user!;

    final Map<String, String> T = {
      'ru': {
        'settings': 'Настройки',
        'language': 'Язык',
        'darkMode': 'Тёмный режим',
        'notifications': 'Push-уведомления',
        'on': 'Вкл',
        'off': 'Выкл',
        'logout': 'Выйти',
        'attended': 'Посещено',
        'saved': 'Избранных',
        'reviews': 'Отзывов',
        'history': 'История посещений',
        'historyEmpty': 'Вы еще не посещали мероприятия',
        'editProfile': 'Редактировать профиль',
      },
      'kz': {
        'settings': 'Баптаулар',
        'language': 'Тіл',
        'darkMode': 'Күңгірт режим',
        'notifications': 'Push-хабарламалар',
        'on': 'Қосу',
        'off': 'Өшіру',
        'logout': 'Шығу',
        'attended': 'Барды',
        'saved': 'Таңдаулы',
        'reviews': 'Пікір',
        'history': 'Қатысу тарихы',
        'historyEmpty': 'Сіз әлі іс-шараларға қатысқан жоқсыз',
        'editProfile': 'Профильді өңдеу',
      },
      'en': {
        'settings': 'Settings',
        'language': 'Language',
        'darkMode': 'Dark Mode',
        'notifications': 'Push Notifications',
        'on': 'On',
        'off': 'Off',
        'logout': 'Log Out',
        'attended': 'Attended',
        'saved': 'Saved',
        'reviews': 'Reviews',
        'history': 'Attended Events',
        'historyEmpty': "You haven't attended any events yet",
        'editProfile': 'Edit Profile',
      },
    }[lang]!;

    final attendedRegs = state.myRegistrations
        .where((r) => r is Map && r['status']?.toString() == 'attended')
        .cast<Map>();
    final attendedCount = attendedRegs.length;

    final isDark = state.isDarkMode;
    final cText   = isDark ? AppColors.darkText   : AppColors.text;
    final cCard   = isDark ? AppColors.darkCard   : AppColors.card;
    final cBg     = isDark ? AppColors.darkBg     : AppColors.bg;
    final cMuted  = isDark ? AppColors.darkMuted  : AppColors.muted;
    final cBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final cSurface= isDark ? AppColors.darkSurface: AppColors.bg;

    String roleLabel() {
      if (user.role == 'admin') {
        return lang == 'kz' ? 'Әкімші' : lang == 'ru' ? 'Администратор' : 'Admin';
      } else if (user.role == 'organizer') {
        return lang == 'kz' ? 'Ұйымдастырушы' : lang == 'ru' ? 'Организатор' : 'Organizer';
      }
      return lang == 'kz' ? 'Студент' : lang == 'ru' ? 'Студент' : 'Student';
    }

    Color roleAccent() {
      if (user.role == 'admin') return const Color(0xFFE84393);
      if (user.role == 'organizer') return AppColors.secondary;
      return AppColors.primaryLight;
    }

    // ── Hero widget (reused below) ──────────────────────────────────────
    Widget heroContent = Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: roleAccent().withValues(alpha: 0.6),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: roleAccent().withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  user.initials,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: roleAccent().withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: roleAccent().withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            '${roleLabel()} · Astana IT University',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () async {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
            if (updated == true && mounted) setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, color: AppColors.primary, size: 15),
                const SizedBox(width: 7),
                Text(
                  T['editProfile']!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Hero — full width ─────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF8), Color(0xFFA29BFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).size.width > 600 ? 20 : 32,
              20,
              MediaQuery.of(context).size.width > 600 ? 16 : 28,
            ),
            child: heroContent,
          ),

          // ── Rest — centered, max 600px ────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Stats (students only)
                  if (user.role == 'student') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cCard,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: cBorder.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _statBox('$attendedCount', T['attended']!, mutedColor: cMuted),
                            _divider(cBorder),
                            _statBox('${state.favorites.length}', T['saved']!, mutedColor: cMuted),
                            _divider(cBorder),
                            _statBox('${state.userRatings.length}', T['reviews']!, mutedColor: cMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Attended history (students only)
                  if (user.role == 'student') ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          T['history']!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cCard,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: cBorder.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: attendedCount == 0
                            ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(Icons.event_busy_rounded,
                                  color: cMuted, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  T['historyEmpty']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: cMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: attendedCount,
                          separatorBuilder: (_, __) => Divider(
                              height: 0.5, color: cBorder),
                          itemBuilder: (_, i) {
                            final reg = attendedRegs.elementAt(i);
                            final ev = reg['eventId'];
                            final title = ev is Map
                                ? (ev['title'] ??
                                ev['titleRu'] ??
                                ev['titleKz'] ??
                                '')
                                .toString()
                                : '';
                            final date = ev is Map
                                ? (ev['eventDate'] ?? ev['date'] ?? '')
                                .toString()
                                : '';
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.event_rounded,
                                          color: AppColors.primary,
                                          size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(title,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: cText,
                                            )),
                                        if (date.isNotEmpty)
                                          Text(date,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: cMuted,
                                              )),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.check_rounded,
                                          color: AppColors.secondary,
                                          size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Settings
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        T['settings']!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: cBorder.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Language
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.language_rounded,
                                        color: AppColors.primary, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(T['language']!,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: cText,
                                      )),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: cBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: Row(
                                    children: ['ru', 'kz', 'en'].map((l) {
                                      final active = state.language == l;
                                      return GestureDetector(
                                        onTap: () => state.setLanguage(l),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: active
                                                ? AppColors.primary
                                                : Colors.transparent,
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: Text(l.toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: active
                                                    ? Colors.white
                                                    : cMuted,
                                              )),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 0.5, color: cBorder),

                          // Dark Mode
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.dark_mode_outlined,
                                        color: AppColors.primary, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(T['darkMode']!,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: cText,
                                      )),
                                ),
                                GestureDetector(
                                  onTap: () => context
                                      .read<AppState>()
                                      .setDarkMode(!state.isDarkMode),
                                  child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    width: 48,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: state.isDarkMode
                                          ? AppColors.primary
                                          : Colors.grey.shade300,
                                      borderRadius:
                                      BorderRadius.circular(14),
                                    ),
                                    child: AnimatedAlign(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      alignment: state.isDarkMode
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.all(3),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                          BorderRadius.circular(11),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                              Colors.black.withValues(alpha: 0.15),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            state.isDarkMode
                                                ? Icons.dark_mode
                                                : Icons.light_mode,
                                            size: 13,
                                            color: state.isDarkMode
                                                ? AppColors.primary
                                                : Colors.orange.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 0.5, color: cBorder),

                          // Notifications
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.notifications_outlined,
                                        color: AppColors.primary, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(T['notifications']!,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: cText,
                                      )),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() =>
                                  _notificationsOn = !_notificationsOn),
                                  child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _notificationsOn
                                          ? AppColors.secondary
                                          : Colors.grey.shade300,
                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _notificationsOn
                                          ? T['on']!
                                          : T['off']!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 0.5, color: cBorder),

                          // Logout
                          InkWell(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: Text(T['logout']!,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700)),
                                content: Text(lang == 'ru'
                                    ? 'Вы уверены, что хотите выйти?'
                                    : lang == 'kz'
                                    ? 'Шығуды қалайсыз ба?'
                                    : 'Are you sure you want to log out?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(lang == 'ru'
                                        ? 'Отмена'
                                        : lang == 'kz'
                                        ? 'Жоқ'
                                        : 'Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      state.logout();
                                    },
                                    child: Text(
                                      lang == 'ru'
                                          ? 'Выйти'
                                          : lang == 'kz'
                                          ? 'Иә'
                                          : 'Log out',
                                      style: const TextStyle(
                                          color: AppColors.danger),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.logout_rounded,
                                          color: AppColors.danger, size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(T['logout']!,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.danger,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String val, String label, {Color? mutedColor}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Text(val,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: mutedColor ?? AppColors.muted,
              )),
        ],
      ),
    ),
  );

  Widget _divider(Color borderColor) => SizedBox(
    height: 44,
    child: VerticalDivider(width: 0.5, color: borderColor),
  );
}
