import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';

class ProfileRegistrationScreen extends StatefulWidget {
  const ProfileRegistrationScreen({super.key});

  @override
  State<ProfileRegistrationScreen> createState() =>
      _ProfileRegistrationScreenState();
}

class _ProfileRegistrationScreenState extends State<ProfileRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

  String? _selectedGender;
  String? _selectedBirthDate;

  // Terms and conditions acceptance
  bool _acceptTerms = false;
  bool _acceptAntiSocial = false;
  bool _acceptNoConviction = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    final profile = AuthService.currentUserProfile;
    if (profile != null) {
      _nameController.text = profile.name ?? '';
      _selectedGender = profile.gender;
      _selectedBirthDate = profile.birthDate;
      _phoneController.text = profile.phone ?? '';
      _emailController.text = profile.email ?? '';
      _inviteCodeController.text = profile.inviteCode ?? '';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      appBar: AppBar(
        backgroundColor: AppColors.lightBeige,
        elevation: 0,
        title: const Text(
          'プロフィール登録',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // 登録名
            _buildLabel('登録名'),
            const SizedBox(height: 8),
            _buildTextField(_nameController, 'ほぐぐ 太郎'),

            const SizedBox(height: 20),

            // 性別
            _buildLabel('性別'),
            const SizedBox(height: 8),
            _buildGenderSelector(),

            const SizedBox(height: 20),

            // 生年月日
            _buildLabel('生年月日'),
            const SizedBox(height: 8),
            _buildDatePicker(),

            const SizedBox(height: 20),

            // 電話番号
            _buildLabel('電話番号'),
            const SizedBox(height: 8),
            _buildPhoneField(),

            const SizedBox(height: 20),

            // Eメール
            _buildLabel('Eメール'),
            const SizedBox(height: 8),
            _buildTextField(_emailController, 'sample@hogugu.com', keyboardType: TextInputType.emailAddress),

            const SizedBox(height: 20),

            // 招待コード
            _buildInviteCodeSection(),

            const SizedBox(height: 30),

            // Terms and conditions acceptance
            _buildTermsSection(),

            const SizedBox(height: 30),

            // 保存ボタン
            _buildSaveButton(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildGenderButton('男性'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGenderButton('女性'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGenderButton('その他'),
        ),
      ],
    );
  }

  Widget _buildGenderButton(String gender) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.lightGray,
          ),
        ),
        child: Text(
          gender,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _selectedBirthDate =
                '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedBirthDate ?? '選択してください',
              style: TextStyle(
                color: _selectedBirthDate != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          const Text(
            '🇯🇵',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          const Text(
            '+81',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '9034881505',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBeige.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondaryOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '招待コード',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'お友達から受け取った招待\nコードを入力してください',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: TextField(
              controller: _inviteCodeController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '登録には、以下の確認および同意が必要です。',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow[700]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '風俗や類するサービスの提供は一切行っておりません。',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '直接取引の禁止も付す',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCheckboxItem(
            value: _acceptTerms,
            onChanged: (value) {
              setState(() {
                _acceptTerms = value ?? false;
              });
            },
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO: Open terms page
                  },
                  child: const Text(
                    '利用規約',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Text(
                  '・',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Open privacy policy page
                  },
                  child: const Text(
                    'プライバシーポリシー',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Text(
                  'に同意します',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckboxItem(
            value: _acceptAntiSocial,
            onChanged: (value) {
              setState(() {
                _acceptAntiSocial = value ?? false;
              });
            },
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '反社会的勢力ではなく、反社会的勢力と交流・関与をしていません',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('反社会的勢力について'),
                        content: const Text(
                          '暴力団、暴力団員、暴力団準構成員、暴力団関係企業、総会屋、'
                          '社会運動標榜ゴロ、政治活動標榜ゴロ、特殊知能暴力集団、'
                          'その他これらに準ずる者を指します。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.question_mark,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckboxItem(
            value: _acceptNoConviction,
            onChanged: (value) {
              setState(() {
                _acceptNoConviction = value ?? false;
              });
            },
            child: const Text(
              '逮捕もしくは起訴されたことはありません',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildSaveButton() {
    final isEnabled = _acceptTerms && _acceptAntiSocial && _acceptNoConviction;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? _handleSave : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppColors.primaryOrange : Colors.grey[400],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: const Text(
          '登録',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[-\s]'), ''));
  }

  int? _calculateAge(String birthDate) {
    try {
      final parts = birthDate.split('/');
      if (parts.length != 3) return null;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final birth = DateTime(year, month, day);
      final today = DateTime.now();

      int age = today.year - birth.year;
      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleSave() async {
    // バリデーション
    if (_nameController.text.trim().isEmpty) {
      _showError('登録名を入力してください');
      return;
    }

    if (_nameController.text.trim().length < 2) {
      _showError('登録名は2文字以上で入力してください');
      return;
    }

    if (_selectedGender == null) {
      _showError('性別を選択してください');
      return;
    }

    if (_selectedBirthDate == null) {
      _showError('生年月日を選択してください');
      return;
    }

    // Age validation - must be 18 or older
    final age = _calculateAge(_selectedBirthDate!);
    if (age == null) {
      _showError('生年月日が正しくありません');
      return;
    }
    if (age < 18) {
      _showError('18歳以上の方のみ登録できます');
      return;
    }
    if (age > 120) {
      _showError('生年月日を正しく入力してください');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showError('電話番号を入力してください');
      return;
    }

    if (!_isValidPhone(_phoneController.text.trim())) {
      _showError('電話番号は10桁または11桁の数字で入力してください');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showError('Eメールを入力してください');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('正しいメールアドレスを入力してください\n例: sample@example.com');
      return;
    }

    // プロフィール保存
    final profile = UserProfile()
      ..name = _nameController.text.trim()
      ..gender = _selectedGender
      ..birthDate = _selectedBirthDate
      ..phone = _phoneController.text.trim()
      ..email = _emailController.text.trim()
      ..inviteCode = _inviteCodeController.text.trim();

    await AuthService.saveProfile(profile);

    // マイページから来た場合は戻る、それ以外は決済情報登録画面へ
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/payment-registration');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('入力エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
