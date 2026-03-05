import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/mysql_service.dart';

class ProfileRegistrationScreen extends StatefulWidget {
  final bool isEditMode;

  const ProfileRegistrationScreen({super.key, this.isEditMode = false});

  @override
  State<ProfileRegistrationScreen> createState() =>
      _ProfileRegistrationScreenState();
}

class _ProfileRegistrationScreenState extends State<ProfileRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _prefectureController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();

  String? _selectedGender;
  String? _selectedBirthDate;

  // Invite code validation state
  bool _isValidatingInviteCode = false;
  bool? _inviteCodeValid;
  String? _inviterName;

  // Terms and conditions acceptance
  bool _acceptTerms = false;
  bool _acceptAntiSocial = false;
  bool _acceptNoConviction = false;

  // Error states for real-time validation
  String? _nameError;
  String? _genderError;
  String? _birthDateError;
  String? _phoneError;
  String? _inviteCodeError;
  String? _postalCodeError;
  String? _prefectureError;
  String? _cityError;
  String? _addressError;

  // Real-time validation methods
  void _validateName(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _nameError = '登録名を入力してください';
      } else if (value.trim().length < 2) {
        _nameError = '登録名は2文字以上で入力してください';
      } else {
        _nameError = null;
      }
    });
  }

  void _validatePhone(String value) {
    setState(() {
      final cleanPhone = value.replaceAll(RegExp(r'[-\s]'), '');
      if (value.trim().isEmpty) {
        _phoneError = '電話番号を入力してください';
      } else if (!RegExp(r'^[0-9]{10,11}$').hasMatch(cleanPhone)) {
        _phoneError = '10桁または11桁の数字で入力';
      } else {
        _phoneError = null;
      }
    });
  }

  void _validatePostalCode(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _postalCodeError = '郵便番号を入力してください';
      } else {
        _postalCodeError = null;
      }
    });
  }

  void _validatePrefecture(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _prefectureError = '都道府県を入力してください';
      } else {
        _prefectureError = null;
      }
    });
  }

  void _validateCity(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _cityError = '市区町村を入力してください';
      } else {
        _cityError = null;
      }
    });
  }

  void _validateAddress(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _addressError = '番地を入力してください';
      } else {
        _addressError = null;
      }
    });
  }

  // Validate invite code against API
  Future<void> _validateInviteCode(String code) async {
    if (code.trim().isEmpty) {
      setState(() {
        _inviteCodeValid = null;
        _inviteCodeError = null;
        _inviterName = null;
      });
      return;
    }

    setState(() {
      _isValidatingInviteCode = true;
      _inviteCodeError = null;
    });

    try {
      final result = await MySQLService.instance.validateInviteCode(code.trim().toUpperCase());

      setState(() {
        _isValidatingInviteCode = false;
        if (result['valid'] == true) {
          _inviteCodeValid = true;
          _inviterName = result['inviterName'];
          _inviteCodeError = null;
        } else {
          _inviteCodeValid = false;
          _inviterName = null;
          _inviteCodeError = result['error'] ?? '招待コードが見つかりません';
        }
      });
    } catch (e) {
      setState(() {
        _isValidatingInviteCode = false;
        _inviteCodeValid = false;
        _inviteCodeError = 'エラーが発生しました';
      });
    }
  }

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
      _postalCodeController.text = profile.postalCode ?? '';
      _prefectureController.text = profile.prefecture ?? '';
      _cityController.text = profile.city ?? '';
      _addressController.text = profile.address ?? '';
      _buildingController.text = profile.building ?? '';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _inviteCodeController.dispose();
    _postalCodeController.dispose();
    _prefectureController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      appBar: AppBar(
        backgroundColor: AppColors.lightBeige,
        elevation: 0,
        title: Text(
          widget.isEditMode ? 'プロフィール編集' : 'プロフィール登録',
          style: const TextStyle(
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
            _buildTextField(
              _nameController,
              'セレ スマ子',
              errorText: _nameError,
              onChanged: _validateName,
            ),

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

            // 住所セクション
            _buildLabel('住所'),
            const SizedBox(height: 8),
            Text(
              'サービス提供時の住所を登録してください',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),

            // 郵便番号
            _buildSubLabel('郵便番号', required: true),
            const SizedBox(height: 6),
            _buildTextField(
              _postalCodeController,
              '123-4567',
              keyboardType: TextInputType.number,
              errorText: _postalCodeError,
              onChanged: _validatePostalCode,
            ),

            const SizedBox(height: 12),

            // 都道府県
            _buildSubLabel('都道府県', required: true),
            const SizedBox(height: 6),
            _buildTextField(
              _prefectureController,
              '東京都',
              errorText: _prefectureError,
              onChanged: _validatePrefecture,
            ),

            const SizedBox(height: 12),

            // 市区町村
            _buildSubLabel('市区町村', required: true),
            const SizedBox(height: 6),
            _buildTextField(
              _cityController,
              '渋谷区',
              errorText: _cityError,
              onChanged: _validateCity,
            ),

            const SizedBox(height: 12),

            // 番地
            _buildSubLabel('番地', required: true),
            const SizedBox(height: 6),
            _buildTextField(
              _addressController,
              '1-2-3',
              errorText: _addressError,
              onChanged: _validateAddress,
            ),

            const SizedBox(height: 12),

            // 建物名・部屋番号
            _buildSubLabel('建物名・部屋番号（任意）', required: false),
            const SizedBox(height: 6),
            _buildTextField(_buildingController, 'マンション名 101号室'),

            const SizedBox(height: 20),

            // 招待コード (only show in registration mode, not edit mode)
            if (!widget.isEditMode) ...[
              _buildInviteCodeSection(),
              const SizedBox(height: 20),
            ],

            // Terms and conditions acceptance (only show in registration mode, not edit mode)
            if (!widget.isEditMode) ...[
              _buildTermsSection(),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 30),

            // 保存ボタン
            _buildSaveButton(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = true}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubLabel(String text, {bool required = true}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    String? errorText,
    Function(String)? onChanged,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? Colors.red : AppColors.lightGray,
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderSelector() {
    final hasError = _genderError != null && _genderError!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            _genderError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
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
    final hasError = _birthDateError != null && _birthDateError!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000, 1, 1),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedBirthDate =
                    '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
                _birthDateError = null; // Clear error on selection
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasError ? Colors.red : AppColors.lightGray,
                width: hasError ? 2 : 1,
              ),
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
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            _birthDateError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneField() {
    final hasError = _phoneError != null && _phoneError!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? Colors.red : AppColors.lightGray,
              width: hasError ? 2 : 1,
            ),
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
                  onChanged: _validatePhone,
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
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            _phoneError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInviteCodeSection() {
    // Invite code feature is temporarily disabled
    const bool isInviteCodeEnabled = false;

    return Opacity(
      opacity: isInviteCodeEnabled ? 1.0 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightBeige.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.secondaryOrange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: AppColors.primaryOrange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '招待',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isInviteCodeEnabled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '準備中',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isInviteCodeEnabled
                  ? '招待コードをお持ちの方は入力してください'
                  : '招待機能は現在準備中です',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isInviteCodeEnabled ? Colors.white : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _inviteCodeError != null
                      ? Colors.red
                      : _inviteCodeValid == true
                          ? Colors.green
                          : AppColors.lightGray,
                  width: _inviteCodeValid == true || _inviteCodeError != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inviteCodeController,
                      enabled: isInviteCodeEnabled,
                      style: TextStyle(
                        color: isInviteCodeEnabled ? AppColors.textPrimary : Colors.grey,
                        fontSize: 15,
                        letterSpacing: 2,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '例: ABCD1234',
                        hintStyle: TextStyle(color: isInviteCodeEnabled ? AppColors.textSecondary : Colors.grey[400]),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: isInviteCodeEnabled ? (value) {
                        // Clear validation when typing
                        if (_inviteCodeValid != null || _inviteCodeError != null) {
                          setState(() {
                            _inviteCodeValid = null;
                            _inviteCodeError = null;
                            _inviterName = null;
                          });
                        }
                      } : null,
                    ),
                  ),
                  if (_isValidatingInviteCode && isInviteCodeEnabled)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryOrange,
                      ),
                    )
                  else if (_inviteCodeValid == true && isInviteCodeEnabled)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24)
                  else if (_inviteCodeError != null && isInviteCodeEnabled)
                    const Icon(Icons.error, color: Colors.red, size: 24)
                  else
                    TextButton(
                      onPressed: isInviteCodeEnabled && _inviteCodeController.text.trim().isNotEmpty
                          ? () => _validateInviteCode(_inviteCodeController.text)
                          : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        '確認',
                        style: TextStyle(
                          color: isInviteCodeEnabled && _inviteCodeController.text.trim().isNotEmpty
                              ? AppColors.primaryOrange
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_inviteCodeValid == true && _inviterName != null && isInviteCodeEnabled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_inviterNameさんからの招待コードです',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_inviteCodeError != null && isInviteCodeEnabled) ...[
              const SizedBox(height: 8),
              Text(
                _inviteCodeError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
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
                  '本サービスの利用規約に基づき、当社を介さない本会員とケアスタッフ間の直接取引（直接契約・直接支払等）は一切禁止しております。',
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
                  onTap: () async {
                    final url = Uri.parse('https://celesmile-demo.duckdns.org/terms-of-service.html');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
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
                    launchUrl(Uri.parse('https://celesmile-demo.duckdns.org/privacy-policy.html'),
                        mode: LaunchMode.externalApplication);
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
        child: Text(
          widget.isEditMode ? '編集' : '登録',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
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

    if (_postalCodeController.text.trim().isEmpty) {
      _showError('郵便番号を入力してください');
      return;
    }

    if (_prefectureController.text.trim().isEmpty) {
      _showError('都道府県を入力してください');
      return;
    }

    if (_cityController.text.trim().isEmpty) {
      _showError('市区町村を入力してください');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _showError('番地を入力してください');
      return;
    }

    // ローカルにプロフィール保存
    // 電話番号はSMS認証済みのものを使用
    // Emailは登録済みのcurrentUserを使用
    final phone = AuthService.currentUserPhone ?? _phoneController.text.trim();
    final email = AuthService.currentUser ?? ''; // Use registered email

    final profile = UserProfile()
      ..name = _nameController.text.trim()
      ..gender = _selectedGender
      ..birthDate = _selectedBirthDate
      ..phone = phone
      ..email = email
      ..postalCode = _postalCodeController.text.trim()
      ..prefecture = _prefectureController.text.trim()
      ..city = _cityController.text.trim()
      ..address = _addressController.text.trim()
      ..building = _buildingController.text.trim();

    await AuthService.saveProfile(profile);

    // サーバーのDBにもプロフィールを保存
    final providerId = AuthService.currentUserProviderId;
    if (providerId != null) {
      final result = await MySQLService.instance.updateProviderProfileFull(
        providerId: providerId,
        name: _nameController.text.trim(),
        gender: _selectedGender,
        birthDate: _selectedBirthDate,
        phone: phone,
        email: email,
        postalCode: _postalCodeController.text.trim(),
        prefecture: _prefectureController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        building: _buildingController.text.trim(),
      );

      if (result['success'] != true) {
        print('⚠️ Failed to save profile to server: ${result['error']}');
        // サーバー保存に失敗してもローカルには保存されているので続行
      }

      // Apply invite code if validated (only in registration mode)
      if (!widget.isEditMode && _inviteCodeValid == true && _inviteCodeController.text.trim().isNotEmpty) {
        final inviteResult = await MySQLService.instance.applyInviteCode(
          _inviteCodeController.text.trim().toUpperCase(),
          providerId,
        );

        if (inviteResult['success'] == true) {
          print('✅ Invite code applied successfully');
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(inviteResult['message'] ?? '招待コードが適用されました！'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('⚠️ Failed to apply invite code: ${inviteResult['error']}');
        }
      }
    }

    // マイページから来た場合は戻る、それ以外はダッシュボードへ
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
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
