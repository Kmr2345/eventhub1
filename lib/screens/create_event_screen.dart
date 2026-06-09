import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventhub/widgets/app_snack.dart';
import 'package:eventhub/screens/event_detail_screen.dart';

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
  XFile? _pickedImage;
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text(state.language == 'ru' ? 'Галерея' : state.language == 'kz' ? 'Галерея' : 'Gallery', style: GoogleFonts.inter()),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
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
      _pickedImage = picked;
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

    // Валидация локации — все 3 языка обязательны
    final locRu = _locRu.text.trim();
    final locKz = _locKz.text.trim();
    final locEn = _locEn.text.trim();
    if (locRu.isEmpty) {
      showSnack(context, lang == 'ru' ? 'Укажите место проведения на русском' : lang == 'kz' ? 'Орынды орысша енгізіңіз' : 'Enter location in Russian', isError: true);
      return;
    }
    if (locKz.isEmpty) {
      showSnack(context, lang == 'ru' ? 'Укажите место проведения на казахском' : lang == 'kz' ? 'Орынды қазақша енгізіңіз' : 'Enter location in Kazakh', isError: true);
      return;
    }
    if (locEn.isEmpty) {
      showSnack(context, lang == 'ru' ? 'Укажите место проведения на английском' : lang == 'kz' ? 'Орынды ағылшынша енгізіңіз' : 'Enter location in English', isError: true);
      return;
    }

    // Валидация описания — все 3 языка обязательны
    final descRu = _descRu.text.trim();
    final descKz = _descKz.text.trim();
    final descEn = _descEn.text.trim();
    if (descRu.isEmpty) {
      showSnack(context, lang == 'ru' ? 'Добавьте описание на русском' : lang == 'kz' ? 'Сипаттаманы орысша енгізіңіз' : 'Add description in Russian', isError: true);
      return;
    }
    if (descKz.isEmpty) {
      showSnack(context, lang == 'ru' ? 'Добавьте описание на казахском' : lang == 'kz' ? 'Сипаттаманы қазақша енгізіңіз' : 'Add description in Kazakh', isError: true);
      return;
    }
    if (descEn.isEmpty) {
      showSnack(context, lang == 'ru' ? 'Добавьте описание на английском' : lang == 'kz' ? 'Сипаттаманы ағылшынша енгізіңіз' : 'Add description in English', isError: true);
      return;
    }

    // Валидация вместимости
    final cap = int.tryParse(_capacity.text.trim());
    if (cap == null || cap < 1) {
      showSnack(
        context,
        lang == 'ru'
            ? 'Укажите корректное количество мест (минимум 1)'
            : lang == 'kz'
            ? 'Орын санын дұрыс енгізіңіз (кемінде 1)'
            : 'Enter a valid capacity (minimum 1)',
        isError: true,
      );
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

    // Дата не в прошлом
    final eventDate = DateTime(sd.year, sd.month, sd.day, st.hour, st.minute);
    if (eventDate.isBefore(DateTime.now())) {
      showSnack(
        context,
        lang == 'ru'
            ? 'Дата мероприятия не может быть в прошлом'
            : lang == 'kz'
            ? 'Іс-шара күні өткен болуы мүмкін емес'
            : 'Event date cannot be in the past',
        isError: true,
      );
      return;
    }

    // Проверка на дубликат (одинаковое название + дата + локация)
    final editId = widget.editEvent?.id;
    final isDuplicate = state.myEvents.any((e) {
      if (editId != null && e.id == editId) return false; // при редактировании пропускаем себя
      final sameTitle = e.titleRu.toLowerCase() == titleRu.toLowerCase();
      final sameDate = e.eventDate.year == eventDate.year &&
          e.eventDate.month == eventDate.month &&
          e.eventDate.day == eventDate.day &&
          e.eventDate.hour == eventDate.hour &&
          e.eventDate.minute == eventDate.minute;
      final sameLocation = e.locationRu.toLowerCase() == locRu.toLowerCase();
      return sameTitle && sameDate && sameLocation;
    });

    if (isDuplicate) {
      showSnack(
        context,
        lang == 'ru'
            ? 'Мероприятие с таким названием, датой и местом уже существует'
            : lang == 'kz'
            ? 'Мұндай атаумен, күнмен және орынмен іс-шара бар'
            : 'An event with the same title, date and location already exists',
        isError: true,
      );
      return;
    }

    final data = <String, dynamic>{
      'title': _titleEn.text.trim().isEmpty ? titleRu : _titleEn.text.trim(),
      'titleRu': titleRu,
      'titleKz': _titleKz.text.trim(),
      'description': descEn,
      'descriptionRu': descRu,
      'descriptionKz': descKz,
      'eventDate': eventDate.toIso8601String(),
      'location': locEn,
      'locationRu': locRu,
      'locationKz': locKz,
      'category': _category,
      'image': _uploadedImageUrl ?? (widget.editEvent?.image ?? _unsplash),
      'capacity': cap,
    };

    try {
      final editId = widget.editEvent?.id;
      if (editId != null && editId.isNotEmpty) {
        final updated = await ApiService.updateEvent(editId, data, token);
        final model = EventModel.fromJson(updated);
        state.updateEvent(model);

        if (!mounted) return;
        showSnack(context, lang == 'ru' ? 'Мероприятие обновлено' : lang == 'kz' ? 'Іс-шара жаңартылды' : 'Event updated');
        Navigator.pop(context, true);
      } else {
        final created = await ApiService.createEvent(data, token);
        final model = EventModel.fromJson(created);
        state.addEvent(model);

        if (!mounted) return;
        showSnack(context, getMessage("eventCreated", lang));
        widget.onCreated?.call();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: model)),
              (route) => route.isFirst, // оставляем только MainScreen в стеке
        );
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
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(T['title']!, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        backgroundColor: context.cardColor,
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
                    kIsWeb
                        ? FutureBuilder<Uint8List>(
                      future: _pickedImage!.readAsBytes(),
                      builder: (_, snap) => snap.hasData
                          ? Image.memory(snap.data!, fit: BoxFit.cover)
                          : const Center(child: CircularProgressIndicator()),
                    )
                        : Image.network(
                      Uri.file(_pickedImage!.path).toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white),
                    ),
                    if (_isUploading)
                      Container(
                        color: Colors.black45,
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    if (!_isUploading) ...[
                      Positioned(
                        bottom: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: Text(T['cover']!, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                        ),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _pickedImage = null;
                            _uploadedImageUrl = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ],
                )
                    : widget.editEvent?.image != null && (widget.editEvent?.image ?? '').isNotEmpty
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.editEvent!.image,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: Text(T['cover']!, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _uploadedImageUrl = '';
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
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

            _sectionCard(context, T['name']!, [
              _field(context, '${T['name']!} (Русский)', _titleRu, 'Название на русском'),
              _field(context, '${T['name']!} (Қазақша)', _titleKz, 'Атауы қазақша'),
              _field(context, '${T['name']!} (English)', _titleEn, 'Title in English'),
            ]),

            Row(children: [
              Expanded(child: _field(context, T['date']!, _date, lang == 'ru' ? '25 марта 2025' : lang == 'kz' ? '25 наурыз 2025' : '25 Mar 2025', readOnly: true, onTap: () => _pickDate(lang))),
              const SizedBox(width: 10),
              Expanded(child: _field(context, T['time']!, _time, '14:00', readOnly: true, onTap: () => _pickTime(lang))),
            ]),
            const SizedBox(height: 14),

            _sectionCard(context, T['location']!, [
              _field(context, '${T['location']!} (Русский)', _locRu, 'С 1.2.366'),
              _field(context, '${T['location']!} (Қазақша)', _locKz, 'С 1.2.366'),
              _field(context, '${T['location']!} (English)', _locEn, 'С 1.2.366'),
            ]),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, T['cat']!),
                      Container(
                        decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.borderColor, width: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _category,
                            isExpanded: true,
                            style: GoogleFonts.inter(fontSize: 14, color: context.textColor),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _field(context, T['cap']!, _capacity, '50', inputType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 14),

            _sectionCard(context, T['desc']!, [
              _field(context, '${T['desc']!} (Русский)', _descRu, 'Описание на русском...', maxLines: 3),
              _field(context, '${T['desc']!} (Қазақша)', _descKz, 'Сипаттама...', maxLines: 2),
              _field(context, '${T['desc']!} (English)', _descEn, 'Description...', maxLines: 2),
            ]),

            const SizedBox(height: 8),

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

  Widget _sectionCard(BuildContext context, String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.borderColor, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.6)),
      const SizedBox(height: 10),
      ...children,
    ]),
  );

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.mutedColor)),
  );

  Widget _field(
      BuildContext context,
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
        _label(context, label),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: inputType,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.inter(fontSize: 14, color: context.textColor),
          decoration: InputDecoration(
            hintText: hint, hintStyle: GoogleFonts.inter(color: context.mutedColor),
            filled: true, fillColor: context.bgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderColor, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    ),
  );
}