import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:eventhub/models/event_model.dart';
import 'package:eventhub/theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final String language;
  final bool isFavorite;
  final bool isRegistered;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const EventCard({
    super.key,
    required this.event,
    required this.language,
    required this.isFavorite,
    required this.isRegistered,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final title    = event.getTitle(language);
    final location = event.getLocation(language);
    final gradient = categoryGradient(event.category);
    final fillPct  = event.fillPercent.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 130,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient base
                    Container(decoration: BoxDecoration(gradient: gradient)),
                    // Photo overlay
                    CachedNetworkImage(
                      imageUrl: event.image,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.multiply,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),
                    // Category badge
                    Positioned(
                      bottom: 10, left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          categoryLabel(event.category, language).toUpperCase(),
                          style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    // Registered badge
                    if (isRegistered)
                      Positioned(
                        top: 10, left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
                          child: Text('✓ Registered', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    // Favorite button
                    Positioned(
                      top: 10, right: 12,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                          child: Center(
                            child: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 17, color: isFavorite ? AppColors.pink : AppColors.muted),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('${event.date} · ${event.time}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(location, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress bar + stats
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fillPct,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFF0EDFF),
                            valueColor: AlwaysStoppedAnimation(
                              fillPct > 0.9 ? AppColors.danger : fillPct > 0.7 ? AppColors.warning : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(children: [
                        const Icon(Icons.people_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text('${event.registered}/${event.capacity}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
                      ]),
                      const SizedBox(width: 10),
                      Row(children: [
                        const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(event.rating.toStringAsFixed(1), style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
