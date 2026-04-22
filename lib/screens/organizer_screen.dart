import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class OrganizerScreen extends StatelessWidget {
  const OrganizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state  = context.watch<AppState>();
    final lang   = state.language;
    final events = state.myEvents;

    final totalParticipants = events.fold(0, (s, e) => s + e.registered);
    final avgRating = events.isEmpty ? 0.0 : events.fold(0.0, (s, e) => s + e.rating) / events.length;

    final T = {
      'ru': {'title': 'Мои мероприятия', 'events': 'Событий', 'participants': 'Участников', 'rating': 'Рейтинг', 'registered': 'зарег.', 'edit': 'Редактировать', 'delete': 'Удалить', 'export': 'Экспорт CSV', 'noEvents': 'Нет мероприятий', 'create': 'Создайте первое мероприятие'},
      'kz': {'title': 'Менің іс-шараларым', 'events': 'Іс-шаралар', 'participants': 'Қатысушылар', 'rating': 'Рейтинг', 'registered': 'тіркелді', 'edit': 'Өңдеу', 'delete': 'Жою', 'export': 'CSV экспорт', 'noEvents': 'Іс-шара жоқ', 'create': 'Алғашқы іс-шараны жасаңыз'},
      'en': {'title': 'My Events', 'events': 'Events', 'participants': 'Participants', 'rating': 'Rating', 'registered': 'reg.', 'edit': 'Edit', 'delete': 'Delete', 'export': 'Export CSV', 'noEvents': 'No Events Yet', 'create': 'Create your first event'},
    }[lang]!;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(T['title']!, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
          ),
        ),

        // Stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _statCard(events.length.toString(), T['events']!, Icons.event_rounded, AppColors.primary),
                const SizedBox(width: 10),
                _statCard(totalParticipants.toString(), T['participants']!, Icons.people_rounded, AppColors.secondary),
                const SizedBox(width: 10),
                _statCard(avgRating.toStringAsFixed(1), T['rating']!, Icons.star_rounded, AppColors.warning),
              ],
            ),
          ),
        ),

        // Events list
        events.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎪', style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 14),
                      Text(T['noEvents']!, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      const SizedBox(height: 8),
                      Text(T['create']!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted)),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _OrganizerEventCard(event: events[i], lang: lang, labels: T, state: state),
                  childCount: events.length,
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
          Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _OrganizerEventCard extends StatelessWidget {
  final EventModel event;
  final String lang;
  final Map<String, String> labels;
  final AppState state;
  const _OrganizerEventCard({required this.event, required this.lang, required this.labels, required this.state});

  @override
  Widget build(BuildContext context) {
    final participants = state.getParticipants(event.id);
    final fillPct = event.fillPercent.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(
        children: [
          // Mini banner
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Container(
              height: 80,
              decoration: BoxDecoration(gradient: categoryGradient(event.category)),
              child: Stack(
                children: [
                  Center(child: Opacity(opacity: 0.3, child: Text(_emoji(event.category), style: const TextStyle(fontSize: 48)))),
                  Positioned(
                    bottom: 10, left: 14,
                    child: Text(event.getTitle(lang), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Positioned(
                    top: 8, right: 10,
                    child: Row(
                      children: [
                        _iconBtn(Icons.edit_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEventScreen(editEvent: event)))),
                        const SizedBox(width: 6),
                        _iconBtn(Icons.delete_outline_rounded, () async {
                          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                            title: const Text('Удалить?'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red)))],
                          ));
                          if (ok == true) state.deleteEvent(event.id);
                        }, danger: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: fillPct, minHeight: 6, backgroundColor: const Color(0xFFF0EDFF), valueColor: AlwaysStoppedAnimation(fillPct > 0.9 ? AppColors.danger : AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${event.registered}/${event.capacity} ${labels['registered']}', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted)),
                  ],
                ),

                // Registered emails
                if (participants.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...participants.take(3).map((email) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(email, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text)),
                    ]),
                  )),
                  if (participants.length > 3)
                    Text('+${participants.length - 3} ещё', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],

                const SizedBox(height: 12),
                // Export button
                GestureDetector(
                  onTap: () { /* CSV export logic */ },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(labels['export']!, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool danger = false}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: danger ? AppColors.danger.withOpacity(0.25) : Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
      child: Center(child: Icon(icon, size: 14, color: Colors.white)),
    ),
  );

  String _emoji(String cat) => {'Conference': '🎤', 'Sports': '⚽', 'Workshop': '💻', 'Social': '🎉', 'Art': '🎨', 'Music': '🎵', 'Seminar': '📚'}[cat] ?? '🎯';
}
