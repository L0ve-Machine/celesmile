import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
  List<String> _galleryImageUrls = [];
  List<Uint8List> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

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
  String? _salonId;
  bool _isEditMode = false;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _providerId = args;
    } else if (args is Map) {
      _providerId = args['providerId'] as String?;
      _salonId = args['salonId'] as String?;
      if (_salonId != null) {
        _isEditMode = true;
      }
    }
    if (_isEditMode && _isLoading) {
      _loadSalonData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSalonData() async {
    if (_salonId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final salonData = await MySQLService.instance.getSalonById(_salonId!);
      if (salonData != null && mounted) {
        // Parse gallery_image_urls
        List<String> imageUrls = [];
        if (salonData['gallery_image_urls'] != null) {
          if (salonData['gallery_image_urls'] is List) {
            imageUrls = List<String>.from(salonData['gallery_image_urls']);
          } else if (salonData['gallery_image_urls'] is String) {
            try {
              final parsed = json.decode(salonData['gallery_image_urls']);
              if (parsed is List) {
                imageUrls = List<String>.from(parsed);
              }
            } catch (e) {
              print('Error parsing gallery images: $e');
            }
          }
        }

        setState(() {
          _salonNameController.text = salonData['salon_name'] ?? '';
          _addressController.text = salonData['address'] ?? '';
          _cityController.text = salonData['city'] ?? '';
          _descriptionController.text = salonData['description'] ?? '';
          _selectedCategory = salonData['category'];
          _selectedPrefecture = salonData['prefecture'];
          _galleryImageUrls = imageUrls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('サロン情報の読み込みに失敗しました: $e')),
        );
      }
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

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        // Limit to 5 images
        final filesToAdd = pickedFiles.take(5 - _selectedImages.length).toList();

        for (var file in filesToAdd) {
          final bytes = await file.readAsBytes();
          setState(() {
            _selectedImages.add(bytes);
          });
        }

        if (pickedFiles.length > filesToAdd.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('最大5枚までアップロードできます')),
          );
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の選択に失敗しました: $e')),
      );
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      return [];
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://celesmile-demo.duckdns.org/api/upload/salon-images'),
      );

      for (int i = 0; i < _selectedImages.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            _selectedImages[i],
            filename: 'image_$i.jpg',
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrls = List<String>.from(data['imageUrls']);

        // Convert relative URLs to absolute URLs
        final absoluteUrls = imageUrls.map((url) {
          return 'https://celesmile-demo.duckdns.org$url';
        }).toList();

        return absoluteUrls;
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      print('Error uploading images: $e');
      throw e;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
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

      final salonId = _salonId ?? 'salon_${DateTime.now().millisecondsSinceEpoch}';

      // Upload new images first
      List<String> newlyUploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          newlyUploadedImageUrls = await _uploadImages();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('画像のアップロードに失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Combine existing and newly uploaded image URLs
      final allImageUrls = [..._galleryImageUrls, ...newlyUploadedImageUrls];

      final salonData = {
        'id': salonId,
        'provider_id': _providerId ?? 'provider_test',
        'salon_name': _salonNameController.text,
        'category': _selectedCategory!,
        'prefecture': _selectedPrefecture!,
        'city': _cityController.text,
        'address': _addressController.text,
        'description': _descriptionController.text,
        'gallery_image_urls': allImageUrls.isNotEmpty ? allImageUrls : null,
      };

      try {
        final success = await MySQLService.instance.saveSalon(salonData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode ? 'サロン情報を更新しました' : 'サロン情報を保存しました'),
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
          title: Text(
            _isEditMode ? 'サロン編集' : 'サロン情報',
            style: const TextStyle(
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
        title: Text(
          _isEditMode ? 'サロン編集' : 'サロン情報',
          style: const TextStyle(
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

              // Gallery Images Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        'ギャラリー画像',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '最大5枚',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'サロンの雰囲気や施術例などの画像を選択してください',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Existing images preview (already uploaded)
                  if (_galleryImageUrls.isNotEmpty)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(_galleryImageUrls.length, (index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _galleryImageUrls[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _galleryImageUrls.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),

                  if (_galleryImageUrls.isNotEmpty && _selectedImages.isNotEmpty)
                    const SizedBox(height: 12),

                  // New selected images preview (not yet uploaded)
                  if (_selectedImages.isNotEmpty)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(_selectedImages.length, (index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _selectedImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),

                  if (_selectedImages.isNotEmpty || _galleryImageUrls.isNotEmpty)
                    const SizedBox(height: 16),

                  // Add images button
                  if ((_selectedImages.length + _galleryImageUrls.length) < 5)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate, size: 18),
                        label: Text(_selectedImages.isEmpty ? '画像を選択' : '画像を追加'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentBlue,
                          side: const BorderSide(color: AppColors.accentBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
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
            onPressed: _isUploading ? null : _saveSalonInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isEditMode ? '更新する' : '保存して次へ',
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
