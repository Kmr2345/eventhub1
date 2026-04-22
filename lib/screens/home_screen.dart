import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:eventhub/data/app_state.dart';
import 'package:eventhub/models/event_model.dart';
import 'package:eventhub/services/api_service.dart';
import 'package:eventhub/theme/app_theme.dart';
import 'package:eventhub/widgets/event_card.dart';
import 'package:eventhub/screens/event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EventModel> events = const [];

  Future<void> loadEvents() async {
    final token = context.read<AppState>().token;
    if (token == null || token.isEmpty) return;

    final data = await ApiService.getEvents(token);
    final parsed = data
        .whereType<Map<String, dynamic>>()
        .map(EventModel.fromJson)
        .toList();

    if (!mounted) return;
    setState(() {
      events = parsed;
    });

    context.read<AppState>().setEvents(parsed);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadEvents());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang  = state.language;
    final user  = state.user!;
    final greeting = lang == 'ru' ? 'Привет, ${user.name.split(' ').first} 👋'
        : lang == 'kz' ? 'Сәлем, ${user.name.split(' ').first} 👋'
        : 'Hello, ${user.name.split(' ').first} 👋';
    final sub = lang == 'ru' ? 'Что интересного сегодня?'
        : lang == 'kz' ? 'Бүгін не қызықты?'
        : 'What\'s happening today?';

    final source = events.isNotEmpty ? events : state.events;
    final trending = source.take(3).toList();
    final upcoming = source;

    return CustomScrollView(
      slivers: [
        // Greeting
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.card,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(sub, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
        ),

        // Trending section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              lang == 'ru' ? '🔥 Популярные' : lang == 'kz' ? '🔥 Танымал' : '🔥 Trending',
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: trending.length,
              itemBuilder: (_, i) {
                final e = trending[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: e))),
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      gradient: categoryGradient(e.category),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Stack(
                      children: [
                        Center(child: Text(_categoryEmoji(e.category), style: const TextStyle(fontSize: 36))),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.getTitle(lang), style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text(e.date, style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withOpacity(0.8))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Upcoming
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              lang == 'ru' ? '📅 Ближайшие события' : lang == 'kz' ? '📅 Жақын іс-шаралар' : '📅 Upcoming Events',
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final e = upcoming[i];
              return EventCard(
                event: e,
                language: lang,
                isFavorite: e.isFavorite,
                isRegistered: state.isRegistered(e.id),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: e))),
                onFavorite: () => state.toggleFavorite(e.id),
              );
            },
            childCount: upcoming.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  String _categoryEmoji(String cat) {
    const map = {'Conference': '🎤', 'Sports': '⚽', 'Workshop': '💻', 'Social': '🎉', 'Art': '🎨', 'Music': '🎵', 'Seminar': '📚'};
    return map[cat] ?? '🎯';
  }
}
