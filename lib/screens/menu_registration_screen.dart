import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../services/mysql_service.dart';

class MenuRegistrationScreen extends StatefulWidget {
  const MenuRegistrationScreen({super.key});

  @override
  State<MenuRegistrationScreen> createState() => _MenuRegistrationScreenState();
}

class _MenuRegistrationScreenState extends State<MenuRegistrationScreen> {
  final List<MenuItemData> _menuItems = [];
  String? _providerId;
  String? _salonId;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _providerId = args?['providerId'] as String?;
    _salonId = args?['salonId'] as String?;
    if (_salonId != null && _isLoading) {
      _loadMenus();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMenus() async {
    if (_salonId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final menus = await MySQLService.instance.getMenusBySalon(_salonId!);
      if (mounted) {
        setState(() {
          _menuItems.clear();
          for (var menu in menus) {
            final item = MenuItemData();
            item.id = menu['id'];
            item.nameController.text = menu['menu_name'] ?? '';
            item.descriptionController.text = menu['description'] ?? '';
            item.priceController.text = menu['price']?.toString() ?? '';
            item.durationController.text = menu['duration']?.toString() ?? '';
            item.selectedCategory = menu['category'];
            final serviceAreasStr = menu['service_areas'] ?? '';
            item.selectedServiceAreas = serviceAreasStr.isNotEmpty
                ? serviceAreasStr.split(',').map((e) => e.trim()).toList()
                : [];
            item.transportationFeeController.text = menu['transportation_fee']?.toString() ?? '0';

            // Parse duration options
            if (menu['duration_options'] != null && menu['duration_options'].toString().isNotEmpty) {
              item.durationOptions = menu['duration_options'].toString().split(',');
            }

            _menuItems.add(item);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メニューの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  void _addMenuItem() {
    setState(() {
      _menuItems.add(MenuItemData());
    });
  }

  void _removeMenuItem(int index) async {
    final item = _menuItems[index];

    // If it's an existing menu (has an id), delete from database
    if (item.id != null) {
      try {
        await MySQLService.instance.deleteMenu(item.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('メニューを削除しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
          return;
        }
      }
    }

    setState(() {
      _menuItems.removeAt(index);
    });
  }

  Future<void> _saveMenus() async {
    // Validate all menus
    bool allValid = true;
    for (var item in _menuItems) {
      if (!item.isValid()) {
        allValid = false;
        break;
      }
    }

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべてのメニュー項目を正しく入力してください')),
      );
      return;
    }

    if (_menuItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最低1つのメニューを追加してください')),
      );
      return;
    }

    try {
      // Save each menu
      for (var item in _menuItems) {
        final menuId = item.id ?? 'menu_${DateTime.now().millisecondsSinceEpoch}_${_menuItems.indexOf(item)}';

        // Use first duration option as default duration
        final defaultDuration = item.durationOptions.isNotEmpty
            ? int.parse(item.durationOptions.first)
            : 60;

        final menuData = {
          'id': menuId,
          'provider_id': _providerId ?? 'provider_test',
          'salon_id': _salonId ?? '',
          'menu_name': item.nameController.text,
          'description': item.descriptionController.text,
          'price': int.parse(item.priceController.text),
          'duration': defaultDuration,
          'category': item.selectedCategory ?? '',
          'service_areas': item.selectedServiceAreas.join(', '),
          'transportation_fee': int.parse(item.transportationFeeController.text),
          'duration_options': item.durationOptions.join(','),
          'optional_services': item.optionalServices.isNotEmpty
              ? item.optionalServices.map((e) => '${e['name']}:${e['price']}').join(',')
              : '',
        };

        await MySQLService.instance.saveMenu(menuData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_menuItems.length}個のメニューを保存しました'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            'メニュー編集',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          'メニュー編集',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ステップ4',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'サービスメニューを登録',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '提供するサービスの詳細を登録してください',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu items list
                  if (_menuItems.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            Icons.menu_book,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'メニューがまだ登録されていません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '下の「メニューを追加」ボタンから登録してください',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _menuItems.length,
                      itemBuilder: (context, index) {
                        return _buildMenuItemCard(index, _menuItems[index]);
                      },
                    ),

                  const SizedBox(height: 16),

                  // Add menu button
                  OutlinedButton.icon(
                    onPressed: _addMenuItem,
                    icon: const Icon(Icons.add, color: AppColors.accentBlue),
                    label: const Text(
                      'メニューを追加',
                      style: TextStyle(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      side: const BorderSide(color: AppColors.accentBlue, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Info box
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
                        Icon(Icons.lightbulb_outline, color: AppColors.accentBlue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'ヒント：料金と所要時間を明確に記載することで、お客様が予約しやすくなります。複数のコースを用意すると選択肢が広がります。',
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
        ],
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
            onPressed: _menuItems.isEmpty ? null : _saveMenus,
            style: ElevatedButton.styleFrom(
              backgroundColor: _menuItems.isEmpty ? Colors.grey[400] : AppColors.primaryOrange,
              disabledBackgroundColor: Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              _menuItems.isEmpty ? 'メニューを追加してください' : '${_menuItems.length}個のメニューを保存',
              style: const TextStyle(
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

  Widget _buildMenuItemCard(int index, MenuItemData item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.lightGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'メニュー ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentBlue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeMenuItem(index),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Menu name
            _buildTextField(
              controller: item.nameController,
              label: 'メニュー名',
              hint: '例：もみほぐし 60分',
              required: true,
            ),
            const SizedBox(height: 16),

            // Category
            const Text(
              'カテゴリー',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: item.selectedCategory,
                  isExpanded: true,
                  hint: const Text('カテゴリーを選択'),
                  items: ['マッサージ', 'ネイル', 'まつげ', 'ヨガ', 'フィットネス', 'その他']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      item.selectedCategory = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price
            _buildTextField(
              controller: item.priceController,
              label: '料金（円）',
              hint: '5000',
              required: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: item.descriptionController,
              label: 'メニュー説明',
              hint: 'サービスの詳細や特徴を記載してください',
              required: true,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Service Areas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '提供エリア',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MenuItemData.kantoAreas.map((area) {
                    final isSelected = item.selectedServiceAreas.contains(area);
                    return FilterChip(
                      label: Text(area),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            item.selectedServiceAreas.add(area);
                          } else {
                            item.selectedServiceAreas.remove(area);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryOrange.withOpacity(0.3),
                      checkmarkColor: AppColors.primaryOrange,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryOrange
                            : AppColors.lightGray,
                        width: isSelected ? 2 : 1,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primaryOrange
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                if (item.selectedServiceAreas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '※ 少なくとも1つのエリアを選択してください',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Transportation Fee
            _buildTextField(
              controller: item.transportationFeeController,
              label: '交通費（円）',
              hint: '例：1000',
              required: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Duration Options
            const Text(
              'サービス時間オプション',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['30', '60', '90', '120'].map((duration) {
                final isSelected = item.durationOptions.contains(duration);
                return FilterChip(
                  label: Text('${duration}分'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        item.durationOptions.add(duration);
                      } else {
                        if (item.durationOptions.length > 1) {
                          item.durationOptions.remove(duration);
                        }
                      }
                    });
                  },
                  selectedColor: AppColors.primaryOrange.withOpacity(0.3),
                  checkmarkColor: AppColors.primaryOrange,
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool required,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
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
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var item in _menuItems) {
      item.dispose();
    }
    super.dispose();
  }
}

class MenuItemData {
  String? id; // For existing menus
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<String> selectedServiceAreas = []; // 選択された提供エリア
  final TextEditingController transportationFeeController = TextEditingController();
  String? selectedCategory;
  List<String> durationOptions = ['60']; // デフォルトは60分
  List<Map<String, dynamic>> optionalServices = []; // {name: String, price: int}

  // 関東圏の都道府県リスト
  static const List<String> kantoAreas = [
    '東京都',
    '神奈川県',
    '千葉県',
    '埼玉県',
    '茨城県',
    '栃木県',
    '群馬県',
  ];

  bool isValid() {
    return nameController.text.isNotEmpty &&
        priceController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        selectedServiceAreas.isNotEmpty &&
        transportationFeeController.text.isNotEmpty &&
        selectedCategory != null &&
        durationOptions.isNotEmpty;
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    durationController.dispose();
    descriptionController.dispose();
    transportationFeeController.dispose();
  }
}
