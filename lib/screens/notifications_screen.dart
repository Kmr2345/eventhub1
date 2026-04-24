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
    final lang = state.language;
    final title = lang == 'ru' ? 'Уведомления' : lang == 'kz' ? 'Хабарламалар' : 'Notifications';
    final list = state.notifications;

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
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
              ),
            )
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 0.5, color: AppColors.border, indent: 72),
              itemBuilder: (_, i) {
                final n = list[i];
                if (n is! Map) return const SizedBox();
                final isRead = (n['read'] ?? n['isRead']) == true;
                final title = (n['title'] ?? '').toString();
                final body = (n['body'] ?? '').toString();
                final eventId =
                    (n['eventId'] ?? (n['meta'] is Map ? (n['meta']['eventId']) : null))
                        ?.toString();
                final notificationId = (n['_id'] ?? n['id'])?.toString();

                return InkWell(
                  onTap: (eventId == null || eventId.isEmpty)
                      ? null
                      : () async {
                          final appState = context.read<AppState>();
                          final token = appState.token;

                          if (token == null || token.isEmpty) return;
                          if (notificationId == null || notificationId.isEmpty) return;

                          // 1) Update UI immediately
                          if (!isRead) {
                            appState.markNotificationAsRead(notificationId);
                          }

                          // 2) Send to backend (no await)
                          ApiService.markNotificationRead(notificationId, token);

                          // 3) Navigate and wait until user returns
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(eventId: eventId),
                            ),
                          );

                          // 4) Reload notifications after returning
                          if (!context.mounted) return;
                          final data = await ApiService.getNotifications(token);
                          appState.setNotifications(data);
                        },
                  child: Container(
                    color: isRead ? AppColors.card : AppColors.primary.withOpacity(0.03),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Icon(Icons.notifications_rounded, color: AppColors.primary)),
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
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),
                                  if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(body, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, height: 1.4)),
                            ],
                          ),
                        ),
                        if (eventId != null && eventId.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 8, top: 2),
                            child: Icon(Icons.chevron_right_rounded, color: AppColors.muted),
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
