import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final title = lang == 'ru' ? 'Уведомления' : lang == 'kz' ? 'Хабарламалар' : 'Notifications';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.card,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            child: Text(lang == 'ru' ? 'Все прочитано' : lang == 'kz' ? 'Барлығын оқу' : 'Mark all read',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: mockNotifications.length,
        separatorBuilder: (_, __) => const Divider(height: 0.5, color: AppColors.border, indent: 72),
        itemBuilder: (_, i) {
          final n = mockNotifications[i];
          final isRead = n['read'] == 'true';
          return Container(
            color: isRead ? AppColors.card : AppColors.primary.withOpacity(0.03),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(n['emoji']!, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(n['title']!, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: isRead ? FontWeight.w500 : FontWeight.w700, color: AppColors.text))),
                          if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(n['body']!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted, height: 1.4)),
                      const SizedBox(height: 5),
                      Text(n['time']!, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.muted.withOpacity(0.7), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
