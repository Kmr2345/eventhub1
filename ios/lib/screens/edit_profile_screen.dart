import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snack.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user;
    _nameCtrl.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final token = state.token;
    if (token == null) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showSnack(context, _t('nameRequired'));
      return;
    }

    if (_changePassword) {
      if (_currentPassCtrl.text.isEmpty) {
        showSnack(context, _t('currentPassRequired'));
        return;
      }
      if (_newPassCtrl.text.length < 6) {
        showSnack(context, _t('passMinLength'));
        return;
      }
      if (_newPassCtrl.text != _confirmPassCtrl.text) {
        showSnack(context, _t('passMismatch'));
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final result = await ApiService.updateProfile(
        token: token,
        name: name,
        currentPassword: _changePassword ? _currentPassCtrl.text : null,
        newPassword: _changePassword ? _newPassCtrl.text : null,
      );

      // Обновляем локальное состояние
      final updatedUser = UserModel(
        id: state.user!.id,
        name: result['name']?.toString() ?? name,
        email: state.user!.email,
        role: state.user!.role,
      );
      state.login(updatedUser.email, updatedUser.name, updatedUser.role,
          userId: updatedUser.id);

      if (mounted) {
        showSnack(context, _t('saved'));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _t(String key) {
    final lang = context.read<AppState>().language;
    const map = <String, Map<String, String>>{
      'editProfile': {'ru': 'Редактировать профиль', 'kz': 'Профильді өңдеу', 'en': 'Edit Profile'},
      'name': {'ru': 'Имя', 'kz': 'Аты', 'en': 'Name'},
      'changePassword': {'ru': 'Изменить пароль', 'kz': 'Құпия сөзді өзгерту', 'en': 'Change Password'},
      'currentPass': {'ru': 'Текущий пароль', 'kz': 'Ағымдағы құпия сөз', 'en': 'Current Password'},
      'newPass': {'ru': 'Новый пароль', 'kz': 'Жаңа құпия сөз', 'en': 'New Password'},
      'confirmPass': {'ru': 'Подтвердите пароль', 'kz': 'Құпия сөзді растаңыз', 'en': 'Confirm Password'},
      'save': {'ru': 'Сохранить', 'kz': 'Сақтау', 'en': 'Save'},
      'cancel': {'ru': 'Отмена', 'kz': 'Болдырмау', 'en': 'Cancel'},
      'saved': {'ru': 'Профиль обновлён', 'kz': 'Профиль жаңартылды', 'en': 'Profile updated'},
      'nameRequired': {'ru': 'Введите имя', 'kz': 'Атыңызды енгізіңіз', 'en': 'Name is required'},
      'currentPassRequired': {'ru': 'Введите текущий пароль', 'kz': 'Ағымдағы құпия сөзді енгізіңіз', 'en': 'Enter current password'},
      'passMinLength': {'ru': 'Пароль минимум 6 символов', 'kz': 'Кем дегенде 6 таңба', 'en': 'Password must be at least 6 characters'},
      'passMismatch': {'ru': 'Пароли не совпадают', 'kz': 'Құпия сөздер сәйкес келмейді', 'en': 'Passwords do not match'},
    };
    return map[key]?[lang] ?? map[key]?['ru'] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_t('editProfile'),
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar preview
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(user.initials,
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Name field
            _label(_t('name')),
            const SizedBox(height: 6),
            _field(
              controller: _nameCtrl,
              icon: Icons.person_outline_rounded,
              hint: _t('name'),
            ),
            const SizedBox(height: 24),

            // Change password toggle
            InkWell(
              onTap: () => setState(() {
                _changePassword = !_changePassword;
                if (!_changePassword) {
                  _currentPassCtrl.clear();
                  _newPassCtrl.clear();
                  _confirmPassCtrl.clear();
                }
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _changePassword ? AppColors.primary : AppColors.border,
                    width: _changePassword ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: _changePassword ? AppColors.primary : AppColors.muted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_t('changePassword'),
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _changePassword ? AppColors.primary : AppColors.text)),
                    ),
                    AnimatedRotation(
                      turns: _changePassword ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: _changePassword ? AppColors.primary : AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),

            // Password fields (animated)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _changePassword
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _label(_t('currentPass')),
                  const SizedBox(height: 6),
                  _field(
                    controller: _currentPassCtrl,
                    icon: Icons.lock_outline_rounded,
                    hint: _t('currentPass'),
                    obscure: _obscureCurrent,
                    toggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  const SizedBox(height: 14),
                  _label(_t('newPass')),
                  const SizedBox(height: 6),
                  _field(
                    controller: _newPassCtrl,
                    icon: Icons.lock_reset_rounded,
                    hint: _t('newPass'),
                    obscure: _obscureNew,
                    toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 14),
                  _label(_t('confirmPass')),
                  const SizedBox(height: 6),
                  _field(
                    controller: _confirmPassCtrl,
                    icon: Icons.check_circle_outline_rounded,
                    hint: _t('confirmPass'),
                    obscure: _obscureConfirm,
                    toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),

            // Save button
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(_t('save'),
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Center(
                  child: Text(_t('cancel'),
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.muted, letterSpacing: 0.4));

  Widget _field({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.muted, size: 20),
          onPressed: toggleObscure,
        )
            : null,
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}