import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import 'package:eventhub/localization/messages.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
import 'package:eventhub/widgets/app_snack.dart';
import 'event_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _category = 'All';
  bool _scanInFlight = false;

  bool _looksLikeRegistrationId(String v) {
    final s = v.trim();
    if (s.length != 24) return false;
    final re = RegExp(r'^[a-fA-F0-9]{24}$');
    return re.hasMatch(s);
  }

  static const _categories = ['All', 'Conference', 'Sports', 'Workshop', 'Art', 'Music', 'Social', 'Seminar'];
  static const _catEmoji   = {'Conference': '🎤', 'Sports': '⚽', 'Workshop': '💻', 'Art': '🎨', 'Music': '🎵', 'Social': '🎉', 'Seminar': '📚'};

  static const _catLabels = {
    'All':        {'ru': 'Все',         'kz': 'Барлық',    'en': 'All'},
    'Conference': {'ru': 'Конференция', 'kz': 'Конференция','en': 'Conference'},
    'Sports':     {'ru': 'Спорт',       'kz': 'Спорт',      'en': 'Sports'},
    'Workshop':   {'ru': 'Воркшоп',     'kz': 'Воркшоп',    'en': 'Workshop'},
    'Art':        {'ru': 'Искусство',   'kz': 'Өнер',       'en': 'Art'},
    'Music':      {'ru': 'Музыка',      'kz': 'Музыка',     'en': 'Music'},
    'Social':     {'ru': 'Культура',    'kz': 'Мәдениет',  'en': 'Social'},
    'Seminar':    {'ru': 'Семинар',     'kz': 'Семинар',    'en': 'Seminar'},
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang  = state.language;
    final results = state.filtered(query: _query, category: _category);
    final hint = lang == 'ru' ? 'Поиск мероприятий...' : lang == 'kz' ? 'Іс-шара іздеу...' : 'Search events...';

    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.card,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) async {
                // If a QR scanner result is pasted here (registrationId),
                // mark attendance instead of treating it as a search query.
                final state = context.read<AppState>();
                final token = state.token;
                if (!_scanInFlight &&
                    token != null &&
                    token.isNotEmpty &&
                    state.user?.role == 'organizer' &&
                    _looksLikeRegistrationId(v)) {
                  _scanInFlight = true;
                  final code = v.trim();
                  print('SCANNED: $code');
                  try {
                    final result = await ApiService.markAttended(code, token);
                    print('ATTENDED: $result');
                    if (!mounted) return;
                    showSnack(context, getMessage("attendanceMarked", lang));
                    _ctrl.clear();
                    setState(() => _query = '');
                  } catch (e) {
                    print('ERROR: $e');
                    if (!mounted) return;
                    showSnack(context, getMessage("attendanceError", lang), isError: true);
                  } finally {
                    _scanInFlight = false;
                  }
                  return;
                }

                if (!mounted) return;
                setState(() => _query = v);
              },
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted), onPressed: () { _ctrl.clear(); setState(() => _query = ''); })
                    : null,
                filled: true, fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),
        ),

        // Category chips
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.card,
            padding: const EdgeInsets.fromLTRB(16, 10, 0, 12),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat   = _categories[i];
                  final active = _category == cat;
                  final label = (_catLabels[cat] ?? {'ru': cat, 'kz': cat, 'en': cat})[lang] ?? cat;
                  final emoji = cat != 'All' ? '${_catEmoji[cat]} ' : '';
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 0.5),
                      ),
                      child: Text('$emoji$label', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.muted)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Results count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              lang == 'ru' ? 'Результаты · ${results.length} событий'
                  : lang == 'kz' ? 'Нәтижелер · ${results.length} іс-шара'
                  : 'Results · ${results.length} events',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5),
            ),
          ),
        ),

        // Results
        results.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(lang == 'ru' ? 'Ничего не найдено' : lang == 'kz' ? 'Ештеңе табылмады' : 'No events found',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final e = results[i];
                    return EventCard(
                      event: e, language: lang,
                      isFavorite: state.isFavoriteEvent(e.id),
                      isRegistered: state.isRegistered(e.id),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: e))),
                      onFavorite: () {
                        final wasFav = state.isFavoriteEvent(e.id);
                        state.syncToggleFavorite(e.id);
                        showSnack(context, getMessage(wasFav ? "favoriteRemoved" : "favoriteAdded", lang));
                      },
                    );
                  },
                  childCount: results.length,
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}
