import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/mysql_service.dart';

class SalonInfoFormScreen extends StatefulWidget {
  const SalonInfoFormScreen({super.key});

  @override
  State<SalonInfoFormScreen> createState() => _SalonInfoFormScreenState();
}

class _SalonInfoFormScreenState extends State<SalonInfoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;
  List<String> _selectedSubcategories = [];
  String? _selectedPrefecture;
  bool _homeVisit = false;

  final List<String> _prefectures = [
    '東京都',
    '神奈川県',
    '千葉県',
    '埼玉県',
    '茨城県',
    '栃木県',
    '群馬県',
  ];

  final Map<String, List<String>> _categories = {
    '美容・リラクゼーション': [
      'まつげ',
      'ネイル',
      'マッサージ',
      '出張リラクゼーション（鍼灸・整体）',
      '出張パーソナルスタイリスト／ファッションコーディネート',
      'スタイリスト',
      '着付け',
      'タトゥー',
      'メイク',
    ],
    '子育て・家事サポート': [
      '保育',
      '家事',
      '整理収納アドバイザー',
      '出張料理・作り置きシェフ',
      '旅行同行',
    ],
    '記念・ライフスタイル': [
      'ベビーフォト',
      'イベントヘルパー',
      '出張カメラマン（家族写真・プロフィール写真など）',
    ],
    '健康・学び': [
      'フィットネス／ヨガ／ピラティスのインストラクター派遣',
      '語学・音楽・習い事レッスン（ピアノ・英会話など）',
    ],
    'ペット・生活環境': [
      'ペットケア・散歩代行',
      '出張ハウスクリーニング（エアコン・水回り専門）',
    ],
  };

  String? _providerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _providerId = args;
    } else if (args is Map) {
      _providerId = args['providerId'] as String?;
    }
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _addressController.dispose();
    _buildingController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveSalonInfo() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('カテゴリーを選択してください')),
        );
        return;
      }

      if (_selectedPrefecture == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('都道府県を選択してください')),
        );
        return;
      }

      final salonId = 'salon_${DateTime.now().millisecondsSinceEpoch}';

      final salonData = {
        'id': salonId,
        'provider_id': _providerId ?? 'provider_test',
        'salon_name': _salonNameController.text,
        'category': _selectedCategory!,
        'prefecture': _selectedPrefecture!,
        'city': _cityController.text,
        'address': _addressController.text,
        'description': _descriptionController.text,
      };

      try {
        final success = await MySQLService.instance.saveSalon(salonData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('サロン情報を保存しました'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, {
            'completed': true,
            'salonId': salonId,
            'providerId': _providerId,
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('サロン情報の保存に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラーが発生しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
          'サロン情報',
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
              const Text(
                'ステップ2',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'サロン・サービス情報を入力',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Salon name
              _buildTextField(
                controller: _salonNameController,
                label: 'サロン名 / サービス名',
                required: true,
                hint: '例：〇〇マッサージサロン',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'サロン名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category selection
              const Text(
                'カテゴリー',
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: const Text('カテゴリーを選択'),
                    items: _categories.keys.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _selectedSubcategories = [];
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Subcategories
              if (_selectedCategory != null) ...[
                const Text(
                  'サブカテゴリー（複数選択可）',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories[_selectedCategory]!.map((sub) {
                    final isSelected = _selectedSubcategories.contains(sub);
                    return FilterChip(
                      label: Text(sub),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSubcategories.add(sub);
                          } else {
                            _selectedSubcategories.remove(sub);
                          }
                        });
                      },
                      selectedColor: AppColors.accentBlue.withOpacity(0.2),
                      checkmarkColor: AppColors.accentBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.accentBlue : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Prefecture
              const Text(
                '都道府県',
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPrefecture,
                    isExpanded: true,
                    hint: const Text('都道府県を選択'),
                    items: _prefectures.map((pref) {
                      return DropdownMenuItem(
                        value: pref,
                        child: Text(pref),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPrefecture = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // City
              _buildTextField(
                controller: _cityController,
                label: '市区町村',
                required: true,
                hint: '例：渋谷区',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '市区町村を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Address
              _buildTextField(
                controller: _addressController,
                label: '住所',
                required: true,
                hint: '例：恵比寿1-2-3',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '住所を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Building
              _buildTextField(
                controller: _buildingController,
                label: '建物名・部屋番号',
                required: false,
                hint: '例：〇〇ビル 301号室',
              ),
              const SizedBox(height: 20),

              // Home visit option
              CheckboxListTile(
                title: const Text(
                  '出張サービスを提供',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'お客様の自宅やオフィスへの出張サービス',
                  style: TextStyle(fontSize: 13),
                ),
                value: _homeVisit,
                onChanged: (value) {
                  setState(() {
                    _homeVisit = value ?? false;
                  });
                },
                activeColor: AppColors.accentBlue,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'サロン紹介',
                required: true,
                hint: 'サービスの特徴や強みを記載してください',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'サロン紹介を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryOrange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '営業時間は後で詳細設定できます。まずは基本情報を登録しましょう。',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ),
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
            onPressed: _saveSalonInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              '保存して次へ',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool required,
    String? hint,
    int maxLines = 1,
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
          maxLines: maxLines,
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
}
