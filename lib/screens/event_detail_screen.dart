import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:eventhub/data/app_state.dart';
import 'package:eventhub/localization/messages.dart';
import 'package:eventhub/models/event_model.dart';
import 'package:eventhub/services/api_service.dart';
import 'package:eventhub/i18n/labels.dart';
import 'package:eventhub/theme/app_theme.dart';
import 'package:eventhub/widgets/app_snack.dart';
import 'package:eventhub/screens/create_event_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel? event;
  final String? eventId;
  final bool scrollToReviews; // ✅
  const EventDetailScreen({super.key, this.event, this.eventId, this.scrollToReviews = false});
  @override State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _scrollController = ScrollController(); // ✅
  bool _showQR = false;
  bool _isRegistered = false;
  String? _registrationId;
  String? _registrationStatus;
  EventModel? _loaded;

  // Reviews
  List<dynamic> _reviews = [];
  double _avgRating = 0;
  int _totalReviews = 0;
  bool _canReview = false;
  bool _alreadyReviewed = false;
  bool _loadingReviews = true;

  // Review form
  int _selectedRating = 0;
  final _commentCtrl = TextEditingController();
  bool _submittingReview = false;

  EventModel? get _event => widget.event ?? _loaded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ✅
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIfNeeded() async {
    final provided = widget.event;
    if (provided != null) {
      _loaded = provided;
      await _loadRegistrationFor(provided.id);
      await _loadReviews(provided.id);
      _scrollToReviewsIfNeeded(); // ✅
      return;
    }

    final id = widget.eventId;
    if (id == null || id.isEmpty) return;

    final cached = context.read<AppState>().events.where((e) => e.id == id).toList();
    if (cached.isNotEmpty) {
      _loaded = cached.first;
      await _loadRegistrationFor(id);
      await _loadReviews(id);
      if (mounted) setState(() {});
      _scrollToReviewsIfNeeded(); // ✅
      return;
    }

    try {
      final raw = await ApiService.getEventById(id);
      final model = EventModel.fromJson(raw);
      _loaded = model;
      await _loadRegistrationFor(id);
      await _loadReviews(id);
      if (mounted) setState(() {});
      _scrollToReviewsIfNeeded(); // ✅
    } catch (err) {
      print('LOAD EVENT ERROR: ${err.toString()}');
    }
  }

  // ✅ автоскролл к отзывам
  void _scrollToReviewsIfNeeded() {
    if (!widget.scrollToReviews) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  Future<void> _loadReviews(String eventId) async {
    try {
      final data = await ApiService.getReviews(eventId);
      final token = context.read<AppState>().token;
      final role = context.read<AppState>().user?.role ?? 'student';

      Map<String, dynamic>? canReviewData;
      if (token != null && role == 'student') {
        try {
          canReviewData = await ApiService.canReview(eventId, token);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _reviews = data['reviews'] ?? [];
          _avgRating = (data['avgRating'] ?? 0).toDouble();
          _totalReviews = data['total'] ?? 0;
          _canReview = canReviewData?['canReview'] == true;
          _alreadyReviewed = canReviewData?['alreadyReviewed'] == true;
          _loadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _loadRegistrationFor(String eventId) async {
    final token = context.read<AppState>().token;
    if (token == null || token.isEmpty) return;

    try {
      final regs = await ApiService.getMyRegistrations(token);
      Map<String, dynamic>? found;
      for (final r in regs) {
        if (r is! Map) continue;
        final ev = r['eventId'];
        final evId = ev is Map ? (ev['_id'] ?? ev['id'])?.toString() : ev?.toString();
        if (evId == eventId) {
          found = r.cast<String, dynamic>();
          break;
        }
      }

      final status = found?['status']?.toString();
      final regId = (found?['_id'] ?? found?['id'])?.toString();

      if (!mounted) return;
      setState(() {
        _registrationId = regId;
        _registrationStatus = status;
        _isRegistered = found != null && status != 'cancelled';
      });
    } catch (err) {
      print('LOAD REG ERROR: ${err.toString()}');
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) return;
    final token = context.read<AppState>().token;
    if (token == null) return;
    final ev = _event;
    if (ev == null) return;

    setState(() => _submittingReview = true);
    try {
      await ApiService.submitReview(ev.id, _selectedRating, _commentCtrl.text.trim(), token);
      await _loadReviews(ev.id);
      _commentCtrl.clear();

      ev.rating = _avgRating;
      ev.totalRatings = _totalReviews;
      context.read<AppState>().updateEventRating(ev.id, _avgRating, _totalReviews);

      setState(() {
        _selectedRating = 0;
        _submittingReview = false;
        _canReview = false;
        _alreadyReviewed = true;
      });
      if (mounted) showSnack(context, 'Отзыв успешно отправлен!');
    } catch (err) {
      setState(() => _submittingReview = false);
      if (mounted) showSnack(context, err.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final role = state.user?.role ?? 'student';
    final isStudent = role == 'student';
    final isOrganizer = role == 'organizer';
    final isAdmin = role == 'admin';
    final e = _event;

    if (e == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Кнопка Edit видна только админу или организатору-владельцу этого ивента
    final canEdit = isAdmin || (isOrganizer && e.organizerId == (state.user?.id ?? ''));

    final isReg = _isRegistered;
    final isFull = e.spotsLeft <= 0 && !isReg;
    final gradient = categoryGradient(e.category);
    final when = DateFormat('dd MMM yyyy, HH:mm').format(e.eventDate);
    final isPast = e.eventDate.isBefore(DateTime.now());

    final T = {
      'ru': {
        'register': 'Зарегистрироваться',
        'unregister': 'Отменить регистрацию',
        'full': 'Мест нет',
        'organizer': 'Организатор',
        'description': 'Описание',
        'spotsLeft': 'мест осталось',
        'participants': 'участников',
        'share': 'Поделиться',
        'myQr': 'Мой QR-билет',
        'edit': 'Редактировать',
        'eventEnded': 'Мероприятие завершено',
        'reviews': 'Отзывы студентов',
        'noReviews': 'Пока нет отзывов',
        'yourReview': 'Ваш отзыв',
        'writeReview': 'Написать отзыв...',
        'submitReview': 'Отправить отзыв',
        'alreadyReviewed': 'Вы уже оставили отзыв',
        'attendRequired': 'Только посетившие могут оставить отзыв',
        'ratings': 'оценок',
      },
      'kz': {
        'register': 'Тіркелу',
        'unregister': 'Тіркелуді болдырмау',
        'full': 'Орын жоқ',
        'organizer': 'Ұйымдастырушы',
        'description': 'Сипаттама',
        'spotsLeft': 'орын қалды',
        'participants': 'қатысушылар',
        'share': 'Бөлісу',
        'myQr': 'Менің QR-билетім',
        'edit': 'Өңдеу',
        'eventEnded': 'Іс-шара аяқталды',
        'reviews': 'Студенттердің пікірлері',
        'noReviews': 'Әзірше пікір жоқ',
        'yourReview': 'Сіздің пікіріңіз',
        'writeReview': 'Пікір жазыңыз...',
        'submitReview': 'Пікір жіберу',
        'alreadyReviewed': 'Сіз пікір қалдырдыңыз',
        'attendRequired': 'Тек қатысқандар пікір қалдыра алады',
        'ratings': 'баға',
      },
      'en': {
        'register': 'Register',
        'unregister': 'Cancel Registration',
        'full': 'Event is Full',
        'organizer': 'Organizer',
        'description': 'Description',
        'spotsLeft': 'spots left',
        'participants': 'participants',
        'share': 'Share',
        'myQr': 'My QR Ticket',
        'edit': 'Edit',
        'eventEnded': 'Event has ended',
        'reviews': 'Student Reviews',
        'noReviews': 'No reviews yet',
        'yourReview': 'Your Review',
        'writeReview': 'Write a review...',
        'submitReview': 'Submit Review',
        'alreadyReviewed': 'You already reviewed this event',
        'attendRequired': 'Only attendees can leave a review',
        'ratings': 'ratings',
      },
    }[lang]!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        controller: _scrollController, // ✅
        slivers: [
          // Banner
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
              if (canEdit)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => CreateEventScreen(editEvent: e)),
                      );
                      if (updated == true && mounted) {
                        setState(() { _loaded = null; });
                        _loadIfNeeded();
                      }
                    },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.edit_rounded, color: Colors.white, size: 18)),
                    ),
                  ),
                ),
              if (isStudent)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () {
                      final wasFav = state.isFavoriteEvent(e.id);
                      state.syncToggleFavorite(e.id);
                      showSnack(context, getMessage(wasFav ? "favoriteRemoved" : "favoriteAdded", lang));
                    },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: Center(child: Icon(state.isFavoriteEvent(e.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.white, size: 18)),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: BoxDecoration(gradient: gradient)),
                  CachedNetworkImage(
                    imageUrl: e.image,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.35),
                    colorBlendMode: BlendMode.multiply,
                    errorWidget: (_, __, ___) => const SizedBox(),
                  ),
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
                  _infoRow(Icons.calendar_today_rounded, when),
                  _infoRow(Icons.location_on_rounded, e.getLocation(lang)),
                  _infoRow(Icons.people_rounded, '${e.registered}/${e.capacity} · ${e.spotsLeft} ${T['spotsLeft']}'),
                  _infoRow(Icons.star_rounded,
                      _totalReviews > 0
                          ? '${_avgRating.toStringAsFixed(1)} · $_totalReviews ${T['ratings']}'
                          : '${e.rating.toStringAsFixed(1)} · ${e.totalRatings} ${T['ratings']}',
                      starColor: AppColors.warning),

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
                            Text(e.organizerName.isNotEmpty ? e.organizerName : T['organizer']!,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Participants
                  if (e.registered > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          ...List.generate(e.registered.clamp(0, 5), (i) {
                            final colors = [AppColors.primary, AppColors.secondary, AppColors.danger, AppColors.warning, AppColors.pink];
                            return Transform.translate(
                              offset: Offset(i * -8.0, 0),
                              child: Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 2)),
                                child: Center(child: Text((i + 1).toString(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                              ),
                            );
                          }),
                          SizedBox(width: e.registered.clamp(0, 5) * 2.0 + 8),
                          Text('${e.registered} ${T['participants']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                        ],
                      ),
                    ),

                  // Registered badge
                  if (isReg) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(getLabel('registered', lang), style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  Text(T['description']!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  Text(e.getDescription(lang), style: GoogleFonts.inter(fontSize: 14, color: AppColors.text, height: 1.65)),
                  const SizedBox(height: 20),

                  // QR ticket
                  if (isReg && _showQR) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
                      child: Column(
                        children: [
                          Text(e.getTitle(lang), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text), textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(when, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                          const SizedBox(height: 16),
                          if (_registrationId == null)
                            const SizedBox(height: 130, width: 130, child: Center(child: CircularProgressIndicator()))
                          else
                            QrImageView(data: _registrationId!, version: QrVersions.auto, size: 130, foregroundColor: AppColors.primary),
                          const SizedBox(height: 12),
                          Text('ID: ${_registrationId ?? '...'}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text('✓ ${getLabel('registered', lang)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      if (isStudent) ...[
                        if (isPast)
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                              child: Center(
                                child: Text(T['eventEnded']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted)),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onTap: isFull ? null : () async {
                                final token = context.read<AppState>().token;
                                if (token == null || token.isEmpty) {
                                  if (!mounted) return;
                                  showSnack(context, getMessage("loginFirst", lang), isError: true);
                                  return;
                                }
                                try {
                                  if (!isReg) {
                                    await ApiService.registerToEvent(e.id, token);
                                    setState(() { _isRegistered = true; e.registered += 1; });
                                    await _loadRegistrationFor(e.id);
                                    await context.read<AppState>().refreshMyRegistrations();
                                    if (!mounted) return;
                                    showSnack(context, getMessage("eventRegistered", lang));
                                    setState(() {});
                                  } else {
                                    await _loadRegistrationFor(e.id);
                                    final registrationId = _registrationId;
                                    if (registrationId == null || registrationId.isEmpty) {
                                      if (!mounted) return;
                                      showSnack(context, getMessage("registrationNotFound", lang), isError: true);
                                      return;
                                    }
                                    await ApiService.cancelRegistration(registrationId, token);
                                    setState(() { _isRegistered = false; e.registered -= 1; });
                                    await _loadRegistrationFor(e.id);
                                    await context.read<AppState>().refreshMyRegistrations();
                                    if (!mounted) return;
                                    showSnack(context, getMessage("eventCancelled", lang));
                                    setState(() {});
                                  }
                                } catch (err) {
                                  if (!mounted) return;
                                  showSnack(context, err.toString(), isError: true);
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
                        if (isReg && !isPast) ...[
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
                      ],

                      if (canEdit) ...[
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (_) => CreateEventScreen(editEvent: e)),
                              );
                              if (updated == true && mounted) {
                                setState(() { _loaded = null; });
                                _loadIfNeeded();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(T['edit']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],

                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 0.5), borderRadius: BorderRadius.circular(14), color: AppColors.card),
                        child: const Center(child: Icon(Icons.share_rounded, color: AppColors.primary, size: 20)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // REVIEWS SECTION
                  Text(T['reviews']!, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 12),

                  if (isStudent && _canReview) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(T['yourReview']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              final s = i + 1;
                              final filled = _selectedRating >= s;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedRating = s),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded, size: 36, color: filled ? AppColors.warning : AppColors.border),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _commentCtrl,
                            maxLines: 3,
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
                            decoration: InputDecoration(
                              hintText: T['writeReview'],
                              hintStyle: GoogleFonts.inter(color: AppColors.muted),
                              filled: true, fillColor: AppColors.bg,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _selectedRating == 0 || _submittingReview ? null : _submitReview,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: _selectedRating == 0 ? null : const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                                  color: _selectedRating == 0 ? Colors.grey.shade200 : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: _submittingReview
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(T['submitReview']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _selectedRating == 0 ? AppColors.muted : Colors.white)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (isStudent && _alreadyReviewed) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(T['alreadyReviewed']!, style: GoogleFonts.inter(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_loadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 0.5)),
                      child: Center(child: Text(T['noReviews']!, style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted))),
                    )
                  else
                    ...(_reviews.map((r) {
                      if (r is! Map) return const SizedBox();
                      final name = (r['userId'] is Map ? r['userId']['name'] : r['userId'])?.toString() ?? 'Student';
                      final rating = (r['rating'] ?? 0) as int;
                      final comment = r['comment']?.toString() ?? '';
                      final date = r['createdAt'] != null
                          ? DateFormat('dd MMM yyyy').format(DateTime.parse(r['createdAt'].toString()))
                          : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 0.5)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                  child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                                      Text(date, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 16,
                                    color: i < rating ? AppColors.warning : AppColors.border,
                                  )),
                                ),
                              ],
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(comment, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text, height: 1.5)),
                            ],
                          ],
                        ),
                      );
                    }).toList()),

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