import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'organizer_screen.dart';
import 'profile_screen.dart';
import 'create_event_screen.dart';
import 'notifications_screen.dart';
import 'admin_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _lastRole = '';

  static const _prefKeyIndex = 'nav_tab_index';
  static const _prefKeyRole  = 'nav_tab_role';

  @override
  void initState() {
    super.initState();
    _loadSavedIndex();
  }

  Future<void> _loadSavedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole  = prefs.getString(_prefKeyRole) ?? '';
    final savedIndex = prefs.getInt(_prefKeyIndex)   ?? 0;
    // Если роль совпадает — восстанавливаем вкладку, иначе начинаем с 0
    final currentRole = context.read<AppState>().user?.role ?? 'student';
    if (mounted) {
      setState(() {
        _lastRole     = currentRole;
        _currentIndex = (savedRole == currentRole) ? savedIndex : 0;
      });
    }
  }

  Future<void> _setIndex(int i) async {
    setState(() => _currentIndex = i);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyIndex, i);
    await prefs.setString(_prefKeyRole, _lastRole);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final role = state.user?.role ?? 'student';
    final isOrganizer = role == 'organizer';
    final isAdmin = role == 'admin';

    // Сбрасываем индекс только при смене роли
    if (_lastRole != role) {
      _lastRole = role;
      _currentIndex = 0;
      // Сохраняем сброс асинхронно
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt(_prefKeyIndex, 0);
        prefs.setString(_prefKeyRole, role);
      });
    }

    final studentTabs = [
      const HomeScreen(),
      const SearchScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];

    final organizerTabs = [
      const HomeScreen(),
      const SearchScreen(),
      const OrganizerScreen(),
      const CreateEventScreen(),
      const ProfileScreen(),
    ];

    final adminTabs = [
      const HomeScreen(),
      const AdminScreen(),
      const CreateEventScreen(),
      const ProfileScreen(),
    ];

    List<Widget> tabs;
    if (isAdmin) {
      tabs = adminTabs;
    } else if (isOrganizer) {
      tabs = organizerTabs;
    } else {
      tabs = studentTabs;
    }

    final currentIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(context, state, isOrganizer, isAdmin),
      body: IndexedStack(index: currentIndex, children: tabs),
      bottomNavigationBar: _buildBottomNav(state, isOrganizer, isAdmin, currentIndex),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppState state,
      bool isOrganizer, bool isAdmin) {
    final unreadCount = state.notifications.where((n) {
      if (n is! Map) return false;
      final v = n['read'] ?? n['isRead'];
      return v == false;
    }).length;

    return AppBar(
      backgroundColor: AppColors.card,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Astana IT University',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500)),
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight])
                        .createShader(b),
                    child: Text('EventHub',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('ADMIN',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
              color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['ru', 'kz', 'en'].map((l) {
              final active = state.language == l;
              return GestureDetector(
                onTap: () => state.setLanguage(l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l.toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppColors.muted)),
                ),
              );
            }).toList(),
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  height: 16,
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5)),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav(AppState state, bool isOrganizer, bool isAdmin, int currentIndex) {
    final lang = state.language;

    List<Map<String, dynamic>> items;

    if (isAdmin) {
      items = [
        _navItem(Icons.home_rounded, Icons.home_outlined,
            lang == 'ru' ? 'Главная' : lang == 'kz' ? 'Басты' : 'Home'),
        _navItem(Icons.admin_panel_settings_rounded, Icons.admin_panel_settings_outlined,
            lang == 'ru' ? 'Админ' : lang == 'kz' ? 'Админ' : 'Admin'),
        _navItem(Icons.add_circle_rounded, Icons.add_circle_outline_rounded,
            lang == 'ru' ? 'Создать' : lang == 'kz' ? 'Жасау' : 'Create'),
        _navItem(Icons.person_rounded, Icons.person_outline_rounded,
            lang == 'ru' ? 'Профиль' : lang == 'kz' ? 'Профиль' : 'Profile'),
      ];
    } else if (isOrganizer) {
      items = [
        _navItem(Icons.home_rounded, Icons.home_outlined,
            lang == 'ru' ? 'Главная' : lang == 'kz' ? 'Басты' : 'Home'),
        _navItem(Icons.search_rounded, Icons.search_outlined,
            lang == 'ru' ? 'Поиск' : lang == 'kz' ? 'Іздеу' : 'Search'),
        _navItem(Icons.event_note_rounded, Icons.event_note_outlined,
            lang == 'ru' ? 'Мои' : lang == 'kz' ? 'Менікі' : 'My Events'),
        _navItem(Icons.add_circle_rounded, Icons.add_circle_outline_rounded,
            lang == 'ru' ? 'Создать' : lang == 'kz' ? 'Жасау' : 'Create'),
        _navItem(Icons.person_rounded, Icons.person_outline_rounded,
            lang == 'ru' ? 'Профиль' : lang == 'kz' ? 'Профиль' : 'Profile'),
      ];
    } else {
      items = [
        _navItem(Icons.home_rounded, Icons.home_outlined,
            lang == 'ru' ? 'Главная' : lang == 'kz' ? 'Басты' : 'Home'),
        _navItem(Icons.search_rounded, Icons.search_outlined,
            lang == 'ru' ? 'Поиск' : lang == 'kz' ? 'Іздеу' : 'Search'),
        _navItem(Icons.favorite_rounded, Icons.favorite_outline_rounded,
            lang == 'ru' ? 'Избранное' : lang == 'kz' ? 'Таңдаулы' : 'Saved'),
        _navItem(Icons.person_rounded, Icons.person_outline_rounded,
            lang == 'ru' ? 'Профиль' : lang == 'kz' ? 'Профиль' : 'Profile'),
      ];
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = currentIndex == i;
              final isCreate = (item['activeIcon'] as IconData) == Icons.add_circle_rounded;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _setIndex(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isCreate
                          ? Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 22,
                          color: active ? Colors.white : AppColors.primary,
                        ),
                      )
                          : Icon(
                          active
                              ? item['activeIcon'] as IconData
                              : item['icon'] as IconData,
                          size: 24,
                          color: active ? AppColors.primary : AppColors.muted),
                      const SizedBox(height: 3),
                      Text(item['label'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: active ? AppColors.primary : AppColors.muted)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _navItem(IconData activeIcon, IconData icon, String label) =>
      {'activeIcon': activeIcon, 'icon': icon, 'label': label};
}