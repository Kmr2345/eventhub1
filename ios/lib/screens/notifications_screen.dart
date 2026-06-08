import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'event_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AppState>().refreshNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final cBg    = isDark ? AppColors.darkBg    : AppColors.bg;
    final cCard  = isDark ? AppColors.darkCard  : AppColors.card;
    final cText  = isDark ? AppColors.darkText  : AppColors.text;
    final cMuted = isDark ? AppColors.darkMuted : AppColors.muted;
    final cBorder= isDark ? AppColors.darkBorder: AppColors.border;
    final lang = state.language;
    final screenTitle = lang == 'ru' ? 'Уведомления' : lang == 'kz' ? 'Хабарламалар' : 'Notifications';
    final list = state.notifications;

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        title: Text(screenTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        backgroundColor: cCard,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            child: Text(lang == 'ru' ? 'Все прочитано' : lang == 'kz' ? 'Барлығын оқу' : 'Mark all read',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
            onPressed: () async => context.read<AppState>().markAllNotificationsRead(),
          ),
        ],
      ),
      body: list.isEmpty
          ? Center(
        child: Text(
          lang == 'ru'
              ? 'Пока нет уведомлений'
              : lang == 'kz'
              ? 'Әзірге хабарлама жоқ'
              : 'No notifications yet',
          style: GoogleFonts.inter(fontSize: 14, color: cMuted),
        ),
      )
          : ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(height: 0.5, color: cBorder, indent: 72),
        itemBuilder: (_, i) {
          final n = list[i];
          if (n is! Map) return const SizedBox();
          final isRead = (n['read'] ?? n['isRead']) == true;

          // Парсинг с поддержкой трёх языков
          final rawTitle = n['title'];
          final rawBody = n['body'];
          final title = rawTitle is Map
              ? (rawTitle[lang] ?? rawTitle['ru'] ?? '').toString()
              : (rawTitle ?? '').toString();
          final body = rawBody is Map
              ? (rawBody[lang] ?? rawBody['ru'] ?? '').toString()
              : (rawBody ?? '').toString();

          final eventId =
          (n['eventId'] ?? (n['meta'] is Map ? (n['meta']['eventId']) : null))
              ?.toString();
          final notificationId = (n['_id'] ?? n['id'])?.toString();
          final metaType = (n['meta'] is Map ? n['meta']['type'] : null)?.toString();

          return InkWell(
            onTap: () async {
              final appState = context.read<AppState>();
              final token = appState.token;

              if (token == null || token.isEmpty) return;
              if (notificationId == null || notificationId.isEmpty) return;

              if (!isRead) {
                appState.markNotificationAsRead(notificationId);
                ApiService.markNotificationRead(notificationId, token).catchError((_) {
                  ApiService.getNotifications(token).then(appState.setNotifications).catchError((_) {});
                });
              }

              if (eventId == null || eventId.isEmpty) return;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(
                    eventId: eventId,
                    scrollToReviews: metaType == 'newReview',
                  ),
                ),
              );

              if (!context.mounted) return;
              final data = await ApiService.getNotifications(token);
              appState.setNotifications(data);
            },
            child: Container(
              color: isRead ? cCard : AppColors.primary.withOpacity(0.03),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Icon(
                        metaType == 'newReview' ? Icons.star_rounded : Icons.notifications_rounded,
                        color: metaType == 'newReview' ? AppColors.warning : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                  color: cText,
                                ),
                              ),
                            ),
                            if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(body, style: GoogleFonts.inter(fontSize: 12, color: cMuted, height: 1.4)),
                      ],
                    ),
                  ),
                  if (eventId != null && eventId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Icon(Icons.chevron_right_rounded, color: cMuted),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}