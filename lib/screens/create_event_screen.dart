import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:eventhub/data/app_state.dart';
import 'package:eventhub/models/event_model.dart';
import 'package:eventhub/localization/messages.dart';
import 'package:eventhub/services/api_service.dart';
import 'package:eventhub/theme/app_theme.dart';
import 'package:eventhub/widgets/app_snack.dart';

class CreateEventScreen extends StatefulWidget {
  final EventModel? editEvent;
  final VoidCallback? onCreated;
  const CreateEventScreen({super.key, this.editEvent, this.onCreated});
  @override State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late final TextEditingController _titleRu, _titleKz, _titleEn;
  late final TextEditingController _descRu, _descKz, _descEn;
  late final TextEditingController _locRu, _locKz, _locEn;
  late final TextEditingController _date, _time, _capacity;
  String _category = 'Conference';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _pickedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  static const _categories = ['Conference', 'Sports', 'Workshop', 'Art', 'Music', 'Social', 'Seminar', 'Other'];
  static const _unsplash = 'https://images.unsplash.com/photo-1613687969216-40c7b718c025?w=600&q=80';

  @override
  void initState() {
    super.initState();
    final e = widget.editEvent;
    _titleRu = TextEditingController(text: e?.titleRu ?? '');
    _titleKz = TextEditingController(text: e?.titleKz ?? '');
    _titleEn = TextEditingController(text: e?.title ?? '');
    _descRu  = TextEditingController(text: e?.descriptionRu ?? '');
    _descKz  = TextEditingController(text: e?.descriptionKz ?? '');
    _descEn  = TextEditingController(text: e?.description ?? '');
    _locRu   = TextEditingController(text: e?.locationRu ?? '');
    _locKz   = TextEditingController(text: e?.locationKz ?? '');
    _locEn   = TextEditingController(text: e?.location ?? '');
    _date     = TextEditingController(text: e != null ? DateFormat('dd MMM yyyy').format(e.eventDate) : '');
    _time     = TextEditingController(text: e != null ? DateFormat('HH:mm').format(e.eventDate) : '');
    _capacity = TextEditingController(text: e?.capacity.toString() ?? '50');
    _category = e?.category ?? 'Conference';
    if (e != null) {
      _selectedDate = DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
      _selectedTime = TimeOfDay(hour: e.eventDate.hour, minute: e.eventDate.minute);
    }
  }

  Future<void> _pickImage(AppState state) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text(state.language == 'ru' ? 'Галерея' : state.language == 'kz' ? 'Галерея' : 'Gallery', style: GoogleFonts.inter()),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text(state.language == 'ru' ? 'Камера' : state.language == 'kz' ? 'Камера' : 'Camera', style: GoogleFonts.inter()),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _isUploading = true;
      _uploadedImageUrl = null;
    });

    try {
      final url = await ApiService.uploadImage(_pickedImage!, state.token!);
      setState(() {
        _uploadedImageUrl = url;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _pickDate(String lang) async {
    final initial = _selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _date.text = DateFormat('dd MMM yyyy').format(picked);
  }

  Future<void> _pickTime(String lang) async {
    final initial = _selectedTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() => _selectedTime = picked);
    final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
    _time.text = DateFormat('HH:mm').format(dt);
  }

  Future<void> _submit(AppState state, String lang) async {
    final token = state.token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      showSnack(context, getMessage("loginFirst", lang), isError: true);
      return;
    }

    final titleRu = _titleRu.text.trim();
    if (titleRu.isEmpty) {
      showSnack(context, getMessage("enterTitle", lang), isError: true);
      return;
    }

    final sd = _selectedDate;
    final st = _selectedTime;
    if (sd == null || st == null) {
      showSnack(
        context,
        lang == 'ru'
            ? 'Выберите дату и время'
            : lang == 'kz'
            ? 'Күні мен уақытын таңдаңыз'
            : 'Select date and time',
        isError: true,
      );
      return;
    }

    final eventDate = DateTime(sd.year, sd.month, sd.day, st.hour, st.minute);

    final data = <String, dynamic>{
      'title': _titleEn.text.trim().isEmpty ? titleRu : _titleEn.text.trim(),
      'titleRu': titleRu,
      'titleKz': _titleKz.text.trim(),
      'description': _descEn.text.trim(),
      'descriptionRu': _descRu.text.trim(),
      'descriptionKz': _descKz.text.trim(),
      'eventDate': eventDate.toIso8601String(),
      'location': _locEn.text.trim(),
      'locationRu': _locRu.text.trim(),
      'locationKz': _locKz.text.trim(),
      'category': _category,
      'image': _uploadedImageUrl ?? (widget.editEvent?.image ?? _unsplash),
      'capacity': int.tryParse(_capacity.text.trim()) ?? 50,
    };

    try {
      final editId = widget.editEvent?.id;
      if (editId != null && editId.isNotEmpty) {
        // ── Режим редактирования ──
        final updated = await ApiService.updateEvent(editId, data, token);
        final model = EventModel.fromJson(updated);
        state.updateEvent(model);

        if (!mounted) return;
        showSnack(context, lang == 'ru' ? 'Мероприятие обновлено' : lang == 'kz' ? 'Іс-шара жаңартылды' : 'Event updated');
        Navigator.pop(context, true); // true → event_detail_screen перезагружает данные
      } else {
        // ── Режим создания ──
        final created = await ApiService.createEvent(data, token);
        final model = EventModel.fromJson(created);
        state.addEvent(model);

        if (!mounted) return;
        showSnack(context, getMessage("eventCreated", lang));
        widget.onCreated?.call();
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('ERROR: ${e.toString()}');
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final lang  = state.language;
    final isEdit = widget.editEvent != null;

    final T = {
      'ru': {'title': isEdit ? 'Редактировать' : 'Новое мероприятие', 'name': 'Название', 'desc': 'Описание', 'location': 'Место', 'date': 'Дата', 'time': 'Время', 'cat': 'Категория', 'cap': 'Кол-во мест', 'cancel': 'Отмена', 'save': isEdit ? 'Сохранить' : 'Создать', 'cover': 'Загрузить обложку'},
      'kz': {'title': isEdit ? 'Өңдеу' : 'Жаңа іс-шара', 'name': 'Атауы', 'desc': 'Сипаттама', 'location': 'Орны', 'date': 'Күні', 'time': 'Уақыты', 'cat': 'Санат', 'cap': 'Орын саны', 'cancel': 'Болдырмау', 'save': isEdit ? 'Сақтау' : 'Жасау', 'cover': 'Мұқаба жүктеу'},
      'en': {'title': isEdit ? 'Edit Event' : 'New Event', 'name': 'Title', 'desc': 'Description', 'location': 'Location', 'date': 'Date', 'time': 'Time', 'cat': 'Category', 'cap': 'Capacity', 'cancel': 'Cancel', 'save': isEdit ? 'Save' : 'Create', 'cover': 'Upload Cover'},
    }[lang]!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(T['title']!, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.card,
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: () async => _submit(state, lang),
            child: Text(T['save']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover upload
            GestureDetector(
              onTap: () => _pickImage(state),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.primary.withOpacity(0.04),
                ),
                clipBehavior: Clip.hardEdge,
                child: _pickedImage != null
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_pickedImage!, fit: BoxFit.cover),
                    if (_isUploading)
                      Container(
                        color: Colors.black45,
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    if (!_isUploading)
                      Positioned(
                        bottom: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: Text(T['cover']!, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                        ),
                      ),
                  ],
                )
                    : Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 36),
                    const SizedBox(height: 8),
                    Text(T['cover']!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ],
                )),
              ),
            ),
            const SizedBox(height: 16),

            // Title section
            _sectionCard(T['name']!, [
              _field('${T['name']!} (Русский)', _titleRu, 'Название на русском'),
              _field('${T['name']!} (Қазақша)', _titleKz, 'Атауы қазақша'),
              _field('${T['name']!} (English)', _titleEn, 'Title in English'),
            ]),

            // Date & Time
            Row(children: [
              Expanded(child: _field(T['date']!, _date, lang == 'ru' ? '25 марта 2025' : lang == 'kz' ? '25 наурыз 2025' : '25 Mar 2025', readOnly: true, onTap: () => _pickDate(lang))),
              const SizedBox(width: 10),
              Expanded(child: _field(T['time']!, _time, '14:00', readOnly: true, onTap: () => _pickTime(lang))),
            ]),
            const SizedBox(height: 14),

            // Location section
            _sectionCard(T['location']!, [
              _field('${T['location']!} (Русский)', _locRu, 'С 1.2.366'),
              _field('${T['location']!} (Қазақша)', _locKz, 'С 1.2.366'),
              _field('${T['location']!} (English)', _locEn, 'С 1.2.366'),
            ]),

            // Category & Capacity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(T['cat']!),
                      Container(
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _category,
                            isExpanded: true,
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _field(T['cap']!, _capacity, '50', inputType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 14),

            // Description section
            _sectionCard(T['desc']!, [
              _field('${T['desc']!} (Русский)', _descRu, 'Описание на русском...', maxLines: 3),
              _field('${T['desc']!} (Қазақша)', _descKz, 'Сипаттама...', maxLines: 2),
              _field('${T['desc']!} (English)', _descEn, 'Description...', maxLines: 2),
            ]),

            const SizedBox(height: 8),

            // Submit button
            GestureDetector(
              onTap: () async => _submit(state, lang),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(T['save']!, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.6)),
      const SizedBox(height: 10),
      ...children,
    ]),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
  );

  Widget _field(
      String label,
      TextEditingController ctrl,
      String hint, {
        int maxLines = 1,
        TextInputType inputType = TextInputType.text,
        bool readOnly = false,
        VoidCallback? onTap,
      }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: inputType,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint, hintStyle: GoogleFonts.inter(color: AppColors.muted),
            filled: true, fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    ),
  );
}