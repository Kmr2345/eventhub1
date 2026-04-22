import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'organizer_screen.dart';
import 'profile_screen.dart';
import 'create_event_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isOrganizer = state.user?.role == 'organizer';

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
      const ProfileScreen(),
    ];

    final tabs = isOrganizer ? organizerTabs : studentTabs;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(context, state, isOrganizer),
      body: IndexedStack(index: _currentIndex, children: tabs),
      floatingActionButton: isOrganizer
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(state, isOrganizer),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppState state, bool isOrganizer) {
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
              Text('Astana IT University', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w500)),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]).createShader(b),
                child: Text('EventHub', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Language switcher in header
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
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
                  child: Text(l.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.muted)),
                ),
              );
            }).toList(),
          ),
        ),
        // Notifications bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(color: AppColors.danger, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                child: Center(child: Text('3', style: GoogleFonts.dmSans(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav(AppState state, bool isOrganizer) {
    final lang = state.language;

    final studentItems = [
      _navItem(Icons.home_rounded, Icons.home_outlined, lang == 'ru' ? 'Главная' : lang == 'kz' ? 'Басты' : 'Home'),
      _navItem(Icons.search_rounded, Icons.search_outlined, lang == 'ru' ? 'Поиск' : lang == 'kz' ? 'Іздеу' : 'Search'),
      _navItem(Icons.favorite_rounded, Icons.favorite_outline_rounded, lang == 'ru' ? 'Избранное' : lang == 'kz' ? 'Таңдаулы' : 'Saved'),
      _navItem(Icons.person_rounded, Icons.person_outline_rounded, lang == 'ru' ? 'Профиль' : lang == 'kz' ? 'Профиль' : 'Profile'),
    ];

    final organizerItems = [
      _navItem(Icons.home_rounded, Icons.home_outlined, lang == 'ru' ? 'Главная' : lang == 'kz' ? 'Басты' : 'Home'),
      _navItem(Icons.search_rounded, Icons.search_outlined, lang == 'ru' ? 'Поиск' : lang == 'kz' ? 'Іздеу' : 'Search'),
      _navItem(Icons.event_note_rounded, Icons.event_note_outlined, lang == 'ru' ? 'Мои' : lang == 'kz' ? 'Менікі' : 'My Events'),
      _navItem(Icons.person_rounded, Icons.person_outline_rounded, lang == 'ru' ? 'Профиль' : lang == 'kz' ? 'Профиль' : 'Profile'),
    ];

    final items = isOrganizer ? organizerItems : studentItems;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              // Insert FAB space in middle for organizer
              if (isOrganizer && i == 2) {
                return const SizedBox(width: 56);
              }
              final item = items[i];
              final active = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(active ? item['activeIcon'] as IconData : item['icon'] as IconData,
                          size: 24, color: active ? AppColors.primary : AppColors.muted),
                      const SizedBox(height: 3),
                      Text(item['label'] as String,
                          style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.muted)),
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
