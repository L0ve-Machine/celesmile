import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/colors.dart';
import '../services/database_service.dart';
import '../services/reviews_database_service.dart';
import '../services/mysql_service.dart';
import '../services/profile_image_service.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceModel? _service;
  List<MenuItem> _selectedMenuItems = [];
  List<ServiceReview> _reviews = [];
  final reviewsDb = ReviewsDatabaseService();
  bool _showAllReviews = false;
  static const int _initialReviewCount = 3;
  Map<String, dynamic>? _providerData;
  Map<String, dynamic>? _salonData;
  List<String> _galleryImages = [];
  bool _isLoadingReviews = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final serviceId = ModalRoute.of(context)?.settings.arguments as String?;

    if (serviceId != null) {
      // Load service from MySQL
      _loadServiceFromMySQL(serviceId);

      // Load reviews from MySQL
      _loadReviews(serviceId);
    }
  }

  Future<void> _loadServiceFromMySQL(String serviceId) async {
    try {
      final serviceData = await MySQLService.instance.getServiceById(serviceId);
      if (serviceData != null && mounted) {
        // Parse menu items from API response
        List<MenuItem> menuItems = [];
        if (serviceData['menu_items'] != null && serviceData['menu_items'] is List) {
          for (var item in serviceData['menu_items']) {
            menuItems.add(MenuItem(
              name: item['name'] ?? '',
              price: item['price'] ?? serviceData['price'] ?? '¥0',
              duration: item['duration'] ?? '60分',
            ));
          }
        }

        // If no menu items, create default one
        if (menuItems.isEmpty) {
          menuItems.add(MenuItem(
            name: serviceData['title'] ?? 'サービス',
            price: serviceData['price'] ?? '¥0',
            duration: '60分',
          ));
        }

        setState(() {
          _service = ServiceModel(
            id: serviceData['id'] ?? '',
            title: serviceData['title'] ?? '',
            provider: serviceData['provider_name'] ?? 'サロン',
            providerTitle: serviceData['provider_title'] ?? serviceData['category'] ?? '',
            price: serviceData['price'] ?? '¥0',
            rating: serviceData['rating']?.toString() ?? '5.0',
            reviews: serviceData['reviews_count']?.toString() ?? '0',
            category: serviceData['category'] ?? '',
            subcategory: serviceData['subcategory'] ?? '',
            location: serviceData['location'] ?? '東京都',
            address: serviceData['address'] ?? '',
            date: '',
            time: '',
            menuItems: menuItems,
            totalPrice: serviceData['price'] ?? '¥0',
            reviewsList: [],
            description: serviceData['description'] ?? '',
            providerId: serviceData['provider_id'],
            salonId: serviceData['salon_id'],
            serviceAreas: serviceData['location'] ?? '東京都',
            transportationFee: 0,
          );

          // Load provider data
          if (_service?.providerId != null) {
            _loadProviderData();
          }

          // Load salon data
          if (_service?.salonId != null) {
            _loadSalonData();
          }
        });
      }
    } catch (e) {
      print('Error loading service: $e');
    }
  }

  Future<void> _loadSalonData() async {
    if (_service?.salonId != null) {
      try {
        final salon = await MySQLService.instance.getSalonById(_service!.salonId!);
        if (salon != null && mounted) {
          setState(() {
            _salonData = salon;
            // Parse gallery_image_urls from JSON
            if (salon['gallery_image_urls'] != null) {
              if (salon['gallery_image_urls'] is List) {
                _galleryImages = List<String>.from(salon['gallery_image_urls']);
              } else if (salon['gallery_image_urls'] is String) {
                try {
                  final parsed = json.decode(salon['gallery_image_urls']);
                  if (parsed is List) {
                    _galleryImages = List<String>.from(parsed);
                  }
                } catch (e) {
                  print('Error parsing gallery images: $e');
                }
              }
            }
          });
        }
      } catch (e) {
        print('Error loading salon data: $e');
      }
    }
  }

  Future<void> _loadProviderData() async {
    if (_service?.providerId != null) {
      final provider = await MySQLService.instance.getProviderById(_service!.providerId!);
      if (mounted) {
        setState(() {
          _providerData = provider;
        });
      }
    }
  }

  Future<void> _loadReviews(String serviceId) async {
    try {
      setState(() {
        _isLoadingReviews = true;
      });

      final reviewsData = await MySQLService.instance.getServiceReviews(serviceId);

      if (mounted) {
        setState(() {
          _reviews = reviewsData.map((reviewMap) {
            return ServiceReview(
              userName: reviewMap['customer_name'] ?? 'ゲスト',
              rating: (reviewMap['rating'] is int)
                  ? (reviewMap['rating'] as int).toDouble()
                  : (reviewMap['rating'] as double),
              comment: reviewMap['comment'] ?? '',
              date: reviewMap['created_at'] != null
                  ? _formatDate(reviewMap['created_at'])
                  : '',
            );
          }).toList();
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _reviews = [];
          _isLoadingReviews = false;
        });
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}年${date.month}月${date.day}日';
    } catch (e) {
      return dateStr;
    }
  }

  double _calculateAverageRating() {
    if (_reviews.isEmpty) return 0.0;
    double sum = 0;
    for (var review in _reviews) {
      sum += review.rating;
    }
    return sum / _reviews.length;
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _selectedMenuItems) {
      final priceStr = item.price.replaceAll('¥', '').replaceAll(',', '').replaceAll('〜', '');
      total += double.tryParse(priceStr) ?? 0;
    }
    return total;
  }

  Future<void> _shareService() async {
    if (_service == null) return;

    try {
      // Generate shareable text
      final serviceTitle = _service!.title;
      final providerName = _service!.provider;
      final price = _service!.price;
      final rating = _service!.rating;
      final location = _service!.location;

      // Create share message
      final shareText = '''
📱 $serviceTitle

🏪 $providerName
📍 $location
⭐ 評価: $rating
💰 料金: $price

詳しくはこちら 👉 https://celesmile-demo.duckdns.org
      '''.trim();

      // Use native share sheet (works on mobile devices)
      await Share.share(
        shareText,
        subject: serviceTitle,
      );
    } catch (e) {
      // If share fails, show a dialog with copy option as fallback
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'サービスをシェア',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_service!.title}\n${_service!.provider}\n評価: ${_service!.rating} ⭐\n料金: ${_service!.price}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                const Text(
                  'リンクをコピーして共有できます',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final text = '${_service!.title} - ${_service!.provider}\n評価: ${_service!.rating} ⭐\n料金: ${_service!.price}\n\nhttps://celesmile-demo.duckdns.org でサービスを確認';
                  await Clipboard.setData(ClipboardData(text: text));
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('クリップボードにコピーしました'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('コピー'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('エラー'),
        ),
        body: const Center(
          child: Text('サービスが見つかりませんでした'),
        ),
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
          _service!.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: _shareService,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gallery images or placeholder
                  if (_galleryImages.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: PageView.builder(
                        itemCount: _galleryImages.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            _galleryImages[index],
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 60,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.white,
                      child: const Icon(
                        Icons.photo_camera,
                        color: AppColors.primaryOrange,
                        size: 60,
                      ),
                    ),

                  // Image indicator dots
                  if (_galleryImages.length > 1) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _galleryImages.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryOrange.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Provider info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ProfileImageService().buildProfileImage(
                          userId: _service!.providerId ?? 'test_provider_001',
                          isProvider: true,
                          size: 60,
                          defaultIcon: Icons.person,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _service!.provider,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _service!.providerTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rating (dynamic from MySQL)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _isLoadingReviews
                        ? const SizedBox(
                            height: 40,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : _reviews.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.lightGray),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_outline, color: Colors.grey[400], size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      'レビューなし',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _calculateAverageRating().toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${_reviews.length}件のレビュー)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                  ),

                  const SizedBox(height: 16),

                  // Service Areas
                  if (_service!.serviceAreas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.primaryOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '提供エリア',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryOrange.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _service!.serviceAreas,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_service!.serviceAreas.isNotEmpty)
                    const SizedBox(height: 16),

                  // Transportation Fee
                  if (_service!.transportationFee > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.train,
                            color: AppColors.accentBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '交通費：',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '¥${_service!.transportationFee.toString()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_service!.transportationFee > 0)
                    const SizedBox(height: 16),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _service!.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Menu options
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'メニューを選択',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._service!.menuItems.map((item) => _buildMenuOption(item)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reviews section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'レビュー',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${_reviews.length}件',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Loading indicator
                        if (_isLoadingReviews)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        // Display average rating
                        if (!_isLoadingReviews && _reviews.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 32),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_calculateAverageRating().toStringAsFixed(1)} / 5.0',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '平均評価',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Show "no reviews" message
                        if (!_isLoadingReviews && _reviews.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.lightGray),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'レビューがありません',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '最初のレビューを投稿してみませんか？',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Show limited or all reviews based on state
                        if (!_isLoadingReviews && _reviews.isNotEmpty)
                          ...(_showAllReviews
                              ? _reviews
                              : _reviews.take(_initialReviewCount))
                              .map((review) => _buildReviewCard(review)),

                        // Show "すべてを見る" button if there are more reviews
                        if (_reviews.length > _initialReviewCount && !_showAllReviews)
                          Center(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showAllReviews = true;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                side: const BorderSide(
                                  color: AppColors.accentBlue,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'すべてを見る',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${_reviews.length - _initialReviewCount}件)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Show "閉じる" button when all reviews are shown
                        if (_showAllReviews && _reviews.length > _initialReviewCount)
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _showAllReviews = false;
                                });
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '閉じる',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_up,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Bottom booking button
          if (_selectedMenuItems.isNotEmpty)
            Container(
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
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '合計',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '¥${_calculateTotal().toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/booking-confirmation',
                            arguments: _service!.id,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '予約に進む',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(MenuItem item) {
    final isSelected = _selectedMenuItems.contains(item);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMenuItems.remove(item);
          } else {
            _selectedMenuItems.add(item);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.lightGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.accentBlue : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (item.duration.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.duration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Duration options
                  if (item.durationOptions.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.durationOptions.map((duration) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.primaryOrange.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            '${duration}分',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    item.price,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.accentBlue : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentBlue : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accentBlue : AppColors.lightGray,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ServiceReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.userName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                review.date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (index) {
                if (index < review.rating.floor()) {
                  return const Icon(Icons.star, color: Colors.amber, size: 16);
                } else if (index < review.rating && review.rating % 1 != 0) {
                  return const Icon(Icons.star_half, color: Colors.amber, size: 16);
                } else {
                  return Icon(Icons.star_border, color: Colors.grey[400], size: 16);
                }
              }),
              const SizedBox(width: 6),
              Text(
                review.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
