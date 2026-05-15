import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:eventhub/data/app_state.dart';
import 'package:eventhub/services/api_service.dart';
import 'package:eventhub/theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _users = [];
  Map<String, dynamic> _stats = {};
  bool _loadingUsers = true;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final token = context.read<AppState>().token ?? '';
    await Future.wait([_loadUsers(token), _loadStats(token)]);
  }

  Future<void> _loadUsers(String token) async {
    try {
      final data = await ApiService.adminGetUsers(token);
      if (mounted) setState(() { _users = data; _loadingUsers = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadStats(String token) async {
    try {
      final data = await ApiService.adminGetStats(token);
      if (mounted) setState(() { _stats = data; _loadingStats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _changeRole(String userId, String currentRole) async {
    final token = context.read<AppState>().token ?? '';
    final roles = ['student', 'organizer', 'admin'];
    String selected = currentRole;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Изменить роль',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: StatefulBuilder(
          builder: (ctx2, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: roles.map((r) => RadioListTile<String>(
              value: r,
              groupValue: selected,
              title: Text(_roleLabel(r),
                  style: GoogleFonts.inter(fontSize: 14)),
              activeColor: AppColors.primary,
              onChanged: (v) => setS(() => selected = v!),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена',
                style: GoogleFonts.inter(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.adminChangeRole(userId, selected, token);
                await _loadUsers(token);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Роль изменена на ${_roleLabel(selected)}'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text('Сохранить',
                style: GoogleFonts.inter(color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId, String name) async {
    final token = context.read<AppState>().token ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Удалить пользователя',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Удалить $name? Это действие нельзя отменить.',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Отмена',
                  style: GoogleFonts.inter(color: AppColors.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Удалить',
                style: GoogleFonts.inter(color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.adminDeleteUser(userId, token);
      await _loadUsers(token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь удалён'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteEvent(String eventId, String title) async {
    final state = context.read<AppState>();
    final token = state.token ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Удалить событие',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Удалить "$title"?',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Отмена',
                  style: GoogleFonts.inter(color: AppColors.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Удалить',
                style: GoogleFonts.inter(color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.adminDeleteEvent(eventId, token);
      state.deleteEvent(eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Событие удалено'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'organizer': return 'Организатор';
      case 'admin': return 'Администратор';
      default: return 'Студент';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'organizer': return Colors.orange;
      case 'admin': return AppColors.primary;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      children: [
        // Tab bar
        Container(
          color: AppColors.card,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Статистика'),
              Tab(text: 'Пользователи'),
              Tab(text: 'События'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStatsTab(),
              _buildUsersTab(),
              _buildEventsTab(state),
            ],
          ),
        ),
      ],
    );
  }

  // ── STATS TAB ──────────────────────────────────────────────────────────
  Widget _buildStatsTab() {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    final cards = [
      {'label': 'Пользователей', 'value': _stats['totalUsers'], 'icon': Icons.people_rounded, 'color': AppColors.primary},
      {'label': 'Студентов', 'value': _stats['students'], 'icon': Icons.school_rounded, 'color': Colors.green},
      {'label': 'Организаторов', 'value': _stats['organizers'], 'icon': Icons.manage_accounts_rounded, 'color': Colors.orange},
      {'label': 'Событий', 'value': _stats['totalEvents'], 'icon': Icons.event_rounded, 'color': Colors.blue},
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Общая статистика',
            style: GoogleFonts.inter(fontSize: 18,
                fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: cards.map((c) => _statCard(
            label: c['label'] as String,
            value: c['value']?.toString() ?? '0',
            icon: c['icon'] as IconData,
            color: c['color'] as Color,
          )).toList(),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.inter(fontSize: 24,
                        fontWeight: FontWeight.w800, color: AppColors.text)),
                Text(label,
                    style: GoogleFonts.inter(fontSize: 11,
                        color: AppColors.muted, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      );

  // ── USERS TAB ──────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_users.isEmpty) {
      return Center(
        child: Text('Нет пользователей',
            style: GoogleFonts.inter(color: AppColors.muted)),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadUsers(context.read<AppState>().token ?? ''),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final u = _users[i] as Map;
          final id = (u['_id'] ?? u['id'])?.toString() ?? '';
          final name = u['name']?.toString() ?? '';
          final email = u['email']?.toString() ?? '';
          final role = u['role']?.toString() ?? 'student';

          return Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _roleColor(role).withOpacity(0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: _roleColor(role)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.text)),
                      Text(email,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.muted)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _roleColor(role).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _roleLabel(role),
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _roleColor(role)),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.muted, size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'role') _changeRole(id, role);
                    if (v == 'delete') _deleteUser(id, name);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'role',
                      child: Row(children: [
                        const Icon(Icons.manage_accounts_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Изменить роль',
                            style: GoogleFonts.inter(fontSize: 13)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Удалить',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── EVENTS TAB ─────────────────────────────────────────────────────────
  Widget _buildEventsTab(AppState state) {
    final events = state.events;
    if (events.isEmpty) {
      return Center(
        child: Text('Нет событий',
            style: GoogleFonts.inter(color: AppColors.muted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = events[i];
        return GestureDetector(
          onTap: () => _showEventDetails(context, e, state),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.getTitle(state.language),
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(e.organizerName,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.muted)),
                      Text('${e.registered} / ${e.capacity} участников',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 22),
                  onPressed: () =>
                      _deleteEvent(e.id, e.getTitle(state.language)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEventDetails(BuildContext context, dynamic e, AppState state) async {
    List<dynamic> participants = [];
    bool loading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            if (loading) {
              ApiService.getEventParticipants(e.id, state.token!).then((data) {
                setModal(() { participants = data; loading = false; });
              }).catchError((_) { setModal(() => loading = false); });
            }
            final lang = state.language;
            final title = e.getTitle(lang);
            final date = DateFormat('dd MMM yyyy, HH:mm').format(e.eventDate);
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(date, style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(e.getLocation(lang), style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Организатор: ${e.organizerName}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.people_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('${e.registered} / ${e.capacity} участников', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                  ]),
                  const Divider(height: 24),
                  Text('Участники', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 10),
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : participants.isEmpty
                      ? Text('Нет зарегистрированных', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted))
                      : SizedBox(
                    height: 220,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: participants.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = participants[i];
                        final user = p['userId'] ?? {};
                        final name = user['name'] ?? '—';
                        final email = user['email'] ?? '—';
                        final status = p['status'] ?? 'registered';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                          title: Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(email, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: status == 'attended' ? Colors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status == 'attended' ? 'Присутствовал' : 'Зарегистрирован',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                                    color: status == 'attended' ? Colors.green : AppColors.primary)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}