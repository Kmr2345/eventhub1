import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:eventhub/data/app_state.dart';
import 'package:eventhub/theme/app_theme.dart';
import 'package:eventhub/widgets/event_card.dart';
import 'package:eventhub/screens/event_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang  = state.language;
    final favs  = state.favorites;

    return favs.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 14),
                Text(lang == 'ru' ? 'Нет избранных' : lang == 'kz' ? 'Таңдаулы жоқ' : 'No saved events',
                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: 8),
                Text(lang == 'ru' ? 'Нажмите ❤️ на карточке события' : lang == 'kz' ? 'Іс-шара картасындағы ❤️ басыңыз' : 'Tap ❤️ on any event card',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(top: 12),
            itemCount: favs.length,
            itemBuilder: (_, i) {
              final e = favs[i];
              return EventCard(
                event: e, language: lang,
                isFavorite: true,
                isRegistered: state.isRegistered(e.id),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: e))),
                onFavorite: () => state.toggleFavorite(e.id),
              );
            },
          );
  }
}
