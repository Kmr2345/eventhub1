import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
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
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.card,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            child: Text(lang == 'ru' ? 'Все прочитано' : lang == 'kz' ? 'Барлығын оқу' : 'Mark all read',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Text(
          lang == 'ru'
              ? 'Пока нет уведомлений'
              : lang == 'kz'
                  ? 'Әзірге хабарлама жоқ'
                  : 'No notifications yet',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
        ),
      ),
    );
  }
}
