import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';

class BankRegistrationScreen extends StatefulWidget {
  const BankRegistrationScreen({super.key});

  @override
  State<BankRegistrationScreen> createState() => _BankRegistrationScreenState();
}

class _BankRegistrationScreenState extends State<BankRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderNameController = TextEditingController();

  String _selectedAccountType = 'normal';
  String? _providerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerId = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _branchNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  void _saveBankAccount() {
    if (_formKey.currentState!.validate()) {
      final providerDb = ProviderDatabaseService();

      final bankAccount = BankAccountInfo(
        providerId: _providerId ?? '',
        bankName: _bankNameController.text,
        branchName: _branchNameController.text,
        accountType: _selectedAccountType,
        accountNumber: _accountNumberController.text,
        accountHolderName: _accountHolderNameController.text,
      );

      providerDb.saveBankAccount(bankAccount);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('銀行口座情報が保存されました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'スタッフ側銀行口座登録',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.account_balance, color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '報酬振込用口座',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'サービス提供による報酬を受け取るための口座情報を登録してください。入力された情報は暗号化されて安全に保管されます。',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bank name
              _buildTextField(
                controller: _bankNameController,
                label: '金融機関名',
                required: true,
                hint: '例：三菱UFJ銀行',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '金融機関名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Branch name
              _buildTextField(
                controller: _branchNameController,
                label: '支店名',
                required: true,
                hint: '例：渋谷支店',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '支店名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Account type
              const Text(
                '口座種別',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '必須',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildAccountTypeOption(
                      value: 'normal',
                      label: '普通',
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAccountTypeOption(
                      value: 'savings',
                      label: '貯蓄',
                      icon: Icons.savings,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Account number
              _buildTextField(
                controller: _accountNumberController,
                label: '口座番号',
                required: true,
                hint: '7桁の数字',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '口座番号を入力してください';
                  }
                  if (value.length != 7) {
                    return '口座番号は7桁で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Account holder name
              _buildTextField(
                controller: _accountHolderNameController,
                label: '口座名義人（カタカナ）',
                required: true,
                hint: '例：ヤマダ タロウ',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '口座名義人を入力してください';
                  }
                  // Check if katakana
                  final katakanaRegex = RegExp(r'^[ァ-ヶー\s]+$');
                  if (!katakanaRegex.hasMatch(value)) {
                    return 'カタカナで入力してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: AppColors.accentBlue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'セキュリティについて',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 入力された口座情報は暗号化されて保存されます\n• 報酬の振込以外の目的で使用されることはありません\n• 第三者に開示されることはありません',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Important notes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppColors.primaryOrange, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'ご注意',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildNote('口座名義人はご本人の名義である必要があります'),
                    _buildNote('入力内容に誤りがあると振込ができません'),
                    _buildNote('ゆうちょ銀行をご利用の場合は、記号・番号ではなく店名・店番・口座番号をご入力ください'),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _saveBankAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              '登録する',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedAccountType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAccountType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.lightGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accentBlue : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.accentBlue : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool required,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '必須',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
