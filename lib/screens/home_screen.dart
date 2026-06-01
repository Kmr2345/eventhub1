import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:eventhub/data/app_state.dart';
import 'package:eventhub/models/event_model.dart';
import 'package:eventhub/services/api_service.dart';
import 'package:eventhub/theme/app_theme.dart';
import 'package:eventhub/widgets/event_card.dart';
import 'package:eventhub/screens/event_detail_screen.dart';
import 'package:eventhub/localization/messages.dart';
import 'package:eventhub/widgets/app_snack.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  Future<void> loadEvents() async {
    if (_isLoading) return;
    final token = context.read<AppState>().token;
    if (token == null || token.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getEvents(token);
      if (!mounted) return;
      final parsed = data
          .whereType<Map<String, dynamic>>()
          .map(EventModel.fromJson)
          .toList();
      // Единственный источник истины — AppState.
      // Не храним локальную копию: все экраны читают из state.events.
      context.read<AppState>().setEvents(parsed);
    } catch (_) {
      // Оставляем текущий список событий без изменений
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadEvents());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;

    // Безопасное получение пользователя — без null-assertion (!)
    final user = state.user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final greeting = lang == 'ru'
        ? 'Привет, ${user.name.split(' ').first} 👋'
        : lang == 'kz'
        ? 'Сәлем, ${user.name.split(' ').first} 👋'
        : 'Hello, ${user.name.split(' ').first} 👋';
    final sub = lang == 'ru'
        ? 'Что интересного сегодня?'
        : lang == 'kz'
        ? 'Бүгін не қызықты?'
        : "What's happening today?";

    final now = DateTime.now();

    // Единственный источник истины для списка событий
    final source = state.events;

    if (source.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (source.isEmpty) {
      return Center(
        child: Text(
          lang == 'ru'
              ? 'Нет мероприятий'
              : lang == 'kz'
              ? 'Іс-шара жоқ'
              : 'No events yet',
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.muted),
        ),
      );
    }

    double popularityScore(EventModel e) {
      return e.registered.toDouble();
    }

    // Trending: топ-3 по популярности среди ещё не прошедших событий
    final trendingTop = (source
        .where((e) => e.eventDate.isAfter(now))
        .toList()
      ..sort((a, b) => popularityScore(b).compareTo(popularityScore(a))))
        .take(5)
        .toList();

    // «Ближайшие» — только будущие события, отсортированные по дате
    final upcoming = source
        .where((e) => e.eventDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    return RefreshIndicator(
      onRefresh: loadEvents,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Greeting
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.card,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting,
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ),
          ),

          // Trending
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                lang == 'ru'
                    ? '🔥 Популярные'
                    : lang == 'kz'
                    ? '🔥 Танымал'
                    : '🔥 Trending',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.6),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: trendingTop.length,
                itemBuilder: (_, i) {
                  final e = trendingTop[i];
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EventDetailScreen(event: e)),
                      );
                      loadEvents();
                    },
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        gradient: categoryGradient(e.category),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.border, width: 0.5),
                      ),
                      child: Stack(
                        children: [
                          Center(
                              child: Text(_categoryEmoji(e.category),
                                  style: const TextStyle(fontSize: 36))),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.5)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter),
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(16)),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(e.getTitle(lang),
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                      DateFormat('dd MMM yyyy, HH:mm')
                                          .format(e.eventDate),
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.white
                                              .withOpacity(0.8))),
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
                lang == 'ru'
                    ? '📅 Ближайшие события'
                    : lang == 'kz'
                    ? '📅 Жақын іс-шаралар'
                    : '📅 Upcoming Events',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.6),
              ),
            ),
          ),

          if (upcoming.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    lang == 'ru'
                        ? 'Нет предстоящих событий'
                        : lang == 'kz'
                        ? 'Жақын іс-шаралар жоқ'
                        : 'No upcoming events',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.muted),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) {
                  final e = upcoming[i];
                  return EventCard(
                    event: e,
                    language: lang,
                    isFavorite: state.isFavoriteEvent(e.id),
                    isRegistered: state.isRegistered(e.id),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EventDetailScreen(event: e)),
                      );
                      loadEvents();
                    },
                    onFavorite: () {
                      final wasFav = state.isFavoriteEvent(e.id);
                      state.syncToggleFavorite(e.id);
                      showSnack(
                          context,
                          getMessage(
                              wasFav ? 'favoriteRemoved' : 'favoriteAdded',
                              lang));
                    },
                    showFavoriteButton: state.user?.role != 'organizer',
                  );
                },
                childCount: upcoming.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  String _categoryEmoji(String cat) {
    const map = {
      'Conference': '🎤',
      'Sports': '⚽',
      'Workshop': '💻',
      'Social': '🎉',
      'Art': '🎨',
      'Music': '🎵',
      'Seminar': '📚'
    };
    return map[cat] ?? '🎯';
  }
}