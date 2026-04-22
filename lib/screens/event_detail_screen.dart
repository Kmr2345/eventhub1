import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:eventhub/data/app_state.dart';
import 'package:eventhub/models/event_model.dart';
import 'package:eventhub/services/api_service.dart';
import 'package:eventhub/theme/app_theme.dart';
class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});
  @override State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _showQR    = false;
  int  _hoverStar = 0;

  EventModel get e => widget.event;

  @override
  Widget build(BuildContext context) {
    final state      = context.watch<AppState>();
    final lang       = state.language;
    final isReg      = state.isRegistered(e.id);
    final userRating = state.getUserRating(e.id);
    final isFull     = e.spotsLeft <= 0 && !isReg;
    final gradient   = categoryGradient(e.category);

    final T = {
      'ru': {'register': 'Зарегистрироваться', 'unregister': 'Отменить регистрацию', 'full': 'Мест нет', 'organizer': 'Организатор', 'description': 'Описание', 'rate': 'Оценить мероприятие', 'spotsLeft': 'мест осталось', 'participants': 'участников', 'share': 'Поделиться', 'myQr': 'Мой QR-билет'},
      'kz': {'register': 'Тіркелу', 'unregister': 'Тіркелуді болдырмау', 'full': 'Орын жоқ', 'organizer': 'Ұйымдастырушы', 'description': 'Сипаттама', 'rate': 'Бағалау', 'spotsLeft': 'орын қалды', 'participants': 'қатысушылар', 'share': 'Бөлісу', 'myQr': 'Менің QR-билетім'},
      'en': {'register': 'Register', 'unregister': 'Cancel Registration', 'full': 'Event is Full', 'organizer': 'Organizer', 'description': 'Description', 'rate': 'Rate This Event', 'spotsLeft': 'spots left', 'participants': 'participants', 'share': 'Share', 'myQr': 'My QR Ticket'},
    }[lang]!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Banner with back button
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => state.toggleFavorite(e.id),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: Center(child: Icon(e.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.white, size: 18)),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: BoxDecoration(gradient: gradient)),
                  CachedNetworkImage(imageUrl: e.image, fit: BoxFit.cover, color: Colors.black.withOpacity(0.35), colorBlendMode: BlendMode.multiply, errorWidget: (_, __, ___) => const SizedBox()),
                  Positioned(
                    bottom: 20, left: 20, right: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                          child: Text(categoryLabel(e.category, lang).toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 6),
                        Text(e.getTitle(lang), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta info cards
                  ...[
                    _infoRow(Icons.calendar_today_rounded, '${e.date} · ${e.time}'),
                    _infoRow(Icons.location_on_rounded, e.getLocation(lang)),
                    _infoRow(Icons.people_rounded, '${e.registered}/${e.capacity} · ${e.spotsLeft} ${T['spotsLeft']}'),
                    _infoRow(Icons.star_rounded, '${e.rating.toStringAsFixed(1)} · ${e.totalRatings} оценок', starColor: AppColors.warning),
                  ],

                  const SizedBox(height: 16),

                  // Organizer
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 0.5)),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Text('🏛', style: TextStyle(fontSize: 20))),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(T['organizer']!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
                            Text(e.organizerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Participants avatars
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        final colors = [AppColors.primary, AppColors.secondary, AppColors.danger, AppColors.warning, AppColors.pink];
                        final initials = ['АА','БК','ДМ','ЖН','КС'][i];
                        return Transform.translate(
                          offset: Offset(i * -8.0, 0),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 2)),
                            child: Center(child: Text(initials, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white))),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      Text('+${e.registered - 5} ${T['participants']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(T['description']!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  Text(e.getDescription(lang), style: GoogleFonts.inter(fontSize: 14, color: AppColors.text, height: 1.65)),
                  const SizedBox(height: 20),

                  // Rating (student only)
                  if (state.user?.role == 'student') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 0.5)),
                      child: Column(
                        children: [
                          Text(T['rate']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              final s = i + 1;
                              final filled = (_hoverStar > 0 ? _hoverStar : userRating ?? 0) >= s;
                              return GestureDetector(
                                onTap: () { state.rateEvent(e.id, s); setState(() {}); },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded, size: 32, color: filled ? AppColors.warning : AppColors.border),
                                ),
                              );
                            }),
                          ),
                          if (userRating != null) ...[
                            const SizedBox(height: 8),
                            Text('${lang == 'ru' ? 'Ваша оценка' : lang == 'kz' ? 'Сіздің бағаңыз' : 'Your rating'}: $userRating/5',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // QR ticket (if registered)
                  if (isReg && _showQR) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
                      child: Column(
                        children: [
                          Text(e.getTitle(lang), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text), textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text('${e.date} · ${e.time}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                          const SizedBox(height: 16),
                          QrImageView(data: 'AITU-EVENTHUB-${e.id}-${state.user?.email}', version: QrVersions.auto, size: 130, foregroundColor: AppColors.primary),
                          const SizedBox(height: 12),
                          Text('ID: EH-2025-${e.category.toUpperCase()}-${e.id.padLeft(4, '0')}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text('✓ ${lang == 'ru' ? 'Вы зарегистрированы' : lang == 'kz' ? 'Тіркелдіңіз' : 'You are registered'}',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: isFull
                              ? null
                              : () async {
                                  final token = context.read<AppState>().token;
                                  print('eventId: ${e.id}');
                                  print('token: $token');

                                  if (token == null || token.isEmpty) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Auth token missing')),
                                    );
                                    return;
                                  }

                                  try {
                                    final result = await ApiService.registerToEvent(e.id, token);
                                    print('response: $result');

                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Registered successfully')),
                                    );

                                    // Keep local UI state consistent with the existing flow.
                                    state.toggleRegistration(e.id);
                                    setState(() {});
                                  } catch (err) {
                                    print('error: ${err.toString()}');
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(err.toString())),
                                    );
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              gradient: isFull ? null : (isReg ? null : const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight])),
                              color: isFull ? Colors.grey.shade200 : (isReg ? Colors.white : null),
                              borderRadius: BorderRadius.circular(14),
                              border: isReg ? Border.all(color: AppColors.primary, width: 1.5) : null,
                            ),
                            child: Center(
                              child: Text(
                                isFull ? T['full']! : (isReg ? T['unregister']! : T['register']!),
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isFull ? AppColors.muted : (isReg ? AppColors.primary : Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isReg) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => setState(() => _showQR = !_showQR),
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 1.5), borderRadius: BorderRadius.circular(14)),
                            child: const Center(child: Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 22)),
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 0.5), borderRadius: BorderRadius.circular(14), color: AppColors.card),
                        child: const Center(child: Icon(Icons.share_rounded, color: AppColors.primary, size: 20)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color starColor = AppColors.primary}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Row(
      children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: starColor.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Center(child: Icon(icon, size: 17, color: starColor))),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text))),
      ],
    ),
  );
}
