import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/provider_database_service.dart';

class ListingInformationScreen extends StatefulWidget {
  const ListingInformationScreen({super.key});

  @override
  State<ListingInformationScreen> createState() => _ListingInformationScreenState();
}

class _ListingInformationScreenState extends State<ListingInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _detailedDescriptionController = TextEditingController();
  final TextEditingController _facilitiesController = TextEditingController();
  final TextEditingController _accessController = TextEditingController();

  String? _providerId;
  String? _salonId;
  String? _mainImagePath;
  List<String> _galleryImages = [];
  bool _isUploading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _providerId = args?['providerId'] as String?;
    _salonId = args?['salonId'] as String?;
  }

  @override
  void dispose() {
    _taglineController.dispose();
    _detailedDescriptionController.dispose();
    _facilitiesController.dispose();
    _accessController.dispose();
    super.dispose();
  }

  void _uploadMainImage() {
    setState(() {
      _isUploading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _mainImagePath = 'main_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          _isUploading = false;
        });
      }
    });
  }

  void _uploadGalleryImage() {
    setState(() {
      _isUploading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _galleryImages.add('gallery_${DateTime.now().millisecondsSinceEpoch}.jpg');
          _isUploading = false;
        });
      }
    });
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImages.removeAt(index);
    });
  }

  void _saveListing() {
    if (_formKey.currentState!.validate()) {
      if (_mainImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メイン画像をアップロードしてください')),
        );
        return;
      }

      if (_galleryImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('最低1枚のギャラリー画像をアップロードしてください')),
        );
        return;
      }

      final providerDb = ProviderDatabaseService();

      // Get existing salon info
      final salon = providerDb.getSalon(_salonId ?? '');
      if (salon != null) {
        // Update salon with listing information
        final updatedSalon = SalonInfo(
          id: salon.id,
          providerId: salon.providerId,
          salonName: salon.salonName,
          category: salon.category,
          subcategories: salon.subcategories,
          prefecture: salon.prefecture,
          city: salon.city,
          address: salon.address,
          building: salon.building,
          description: salon.description,
          imageUrls: salon.imageUrls,
          homeVisit: salon.homeVisit,
          businessHours: salon.businessHours,
          createdAt: salon.createdAt,
          tagline: _taglineController.text,
          detailedDescription: _detailedDescriptionController.text,
          facilities: _facilitiesController.text,
          accessInfo: _accessController.text,
          mainImageUrl: _mainImagePath,
          galleryImageUrls: _galleryImages,
        );

        providerDb.updateSalon(_salonId ?? '', updatedSalon);
      }

      Navigator.pop(context, {
        'completed': true,
        'providerId': _providerId,
        'salonId': _salonId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('掲載情報が保存されました'),
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
          '掲載情報登録',
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
                'ステップ3',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '掲載情報を登録',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'お客様に魅力的に見えるよう、写真や詳細情報を登録してください',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Main image upload
              const Text(
                'メイン画像',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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

              if (_mainImagePath == null)
                GestureDetector(
                  onTap: _isUploading ? null : _uploadMainImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.lightGray,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: _isUploading
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CircularProgressIndicator(color: AppColors.accentBlue),
                                SizedBox(height: 16),
                                Text(
                                  'アップロード中...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'タップしてメイン画像を選択',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'サロンや施術の雰囲気がわかる写真',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'アップロード完了',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _mainImagePath!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _mainImagePath = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Tagline
              _buildTextField(
                controller: _taglineController,
                label: 'キャッチコピー',
                required: true,
                hint: '例：心と体をほぐす、至福のひととき',
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'キャッチコピーを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Detailed description
              _buildTextField(
                controller: _detailedDescriptionController,
                label: '詳細説明',
                required: true,
                hint: 'サロンの特徴、施術の内容、おすすめポイントなどを詳しく記載してください',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '詳細説明を入力してください';
                  }
                  if (value.length < 50) {
                    return '50文字以上で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Facilities
              _buildTextField(
                controller: _facilitiesController,
                label: '設備・アメニティ',
                required: false,
                hint: '例：シャワー完備、アロマオイル各種、駐車場あり',
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Access info
              _buildTextField(
                controller: _accessController,
                label: 'アクセス情報',
                required: false,
                hint: '例：渋谷駅より徒歩5分、バス停「○○」下車すぐ',
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Gallery images
              const Text(
                'ギャラリー画像',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                  '必須（1枚以上）',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Gallery grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _galleryImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _galleryImages.length) {
                    // Add new image button
                    return GestureDetector(
                      onTap: _isUploading ? null : _uploadGalleryImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.lightGray,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: _isUploading
                              ? const CircularProgressIndicator(
                                  color: AppColors.accentBlue,
                                  strokeWidth: 2,
                                )
                              : Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                        ),
                      ),
                    );
                  }

                  // Gallery image
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeGalleryImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
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
                },
              ),

              const SizedBox(height: 24),

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '写真撮影のポイント',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 明るい場所で撮影しましょう\n• サロンの清潔感が伝わる写真を選びましょう\n• 施術の様子がわかる写真があると◎\n• 3〜5枚の写真を用意すると効果的です',
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
            onPressed: _saveListing,
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
    int? maxLength,
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
          maxLength: maxLength,
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
