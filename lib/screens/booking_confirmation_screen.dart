import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/database_service.dart';
import '../services/booking_history_service.dart';
import '../services/reviews_database_service.dart';
import '../services/provider_database_service.dart';
import '../services/auth_service.dart';
import '../services/stripe_service.dart';
import '../services/payment_method_service.dart';
import '../services/chat_service.dart';
import '../services/mysql_service.dart';
import '../services/profile_image_service.dart';
import '../services/notification_service.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends State<BookingConfirmationScreen> {
  bool _acceptCancellationPolicy = false;
  ServiceModel? _service;
  bool _isViewOnly = false;
  final reviewsDb = ReviewsDatabaseService();
  final TextEditingController _additionalNotesController = TextEditingController();
  Map<String, dynamic>? _providerData;
  Map<String, dynamic>? _salonData;
  List<String> _galleryImages = [];

  // Selected menu items
  List<MenuItem> _selectedMenuItems = [];
  bool _hasInitializedMenus = false;

  // Points and coupons
  int _availablePoints = 0;
  int _usedPoints = 0;
  String? _selectedCoupon;
  List<Map<String, dynamic>> _availableCoupons = [];

  // Saved cards
  List<SavedPaymentMethod> _savedCards = [];
  SavedPaymentMethod? _selectedCard;

  // Payment info for cancellation/refund
  String? _paymentIntentId;
  String? _stripeAccountId;
  int? _paidAmount;

  // Selected date and time
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // Customer address (default to user's address)
  String? _selectedAddress;

  // Reviews data
  List<ServiceReview> _reviews = [];
  bool _isLoadingReviews = true;
  double _averageRating = 0.0;
  int _reviewCount = 0;

  @override
  void dispose() {
    _additionalNotesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get service ID from navigation arguments
    final arguments = ModalRoute.of(context)?.settings.arguments;

    String? serviceId;
    if (arguments is String) {
      // Direct service ID (from dashboard)
      serviceId = arguments;
      _isViewOnly = false;
    } else if (arguments is Map) {
      // Map with serviceId and viewOnly flag (from booking history)
      serviceId = arguments['serviceId'] as String?;
      _isViewOnly = arguments['viewOnly'] as bool? ?? false;
    }

    print('🔍 DEBUG [didChangeDependencies]: serviceId = $serviceId, _hasInitializedMenus = $_hasInitializedMenus');

    if (serviceId != null && !_hasInitializedMenus) {
      // Load service from MySQL - this will set _service
      _loadServiceFromMySQL(serviceId).then((_) {
        // After service is loaded, availability will be loaded when date picker dialog is opened
        print('🔍 DEBUG [didChangeDependencies]: Service loaded');
      });

      // Points will be loaded from backend when available
      _availablePoints = 0;

      // Load coupons from backend
      _loadCoupons();

      // Load saved cards
      _loadSavedCards();

      // Load provider data
      _loadProviderData();

      // Load salon data
      _loadSalonData();

      // Load customer address
      _loadCustomerAddress();

      // Load reviews
      _loadReviews(serviceId);
    }
  }

  void _loadCustomerAddress() {
    final userProfile = AuthService.currentUserProfile;
    if (userProfile != null) {
      final postalCode = userProfile.postalCode ?? '';
      final prefecture = userProfile.prefecture ?? '';
      final city = userProfile.city ?? '';
      final address = userProfile.address ?? '';
      final building = userProfile.building ?? '';

      if (prefecture.isNotEmpty && city.isNotEmpty && address.isNotEmpty) {
        setState(() {
          _selectedAddress = '〒$postalCode $prefecture$city$address${building.isNotEmpty ? " $building" : ""}';
        });
      }
    }
  }

  Future<void> _loadServiceFromMySQL(String serviceId) async {
    print('🔍 DEBUG [_loadServiceFromMySQL]: Loading service with ID = $serviceId');
    try {
      final serviceData = await MySQLService.instance.getServiceById(serviceId);
      print('🔍 DEBUG [_loadServiceFromMySQL]: Service data received = $serviceData');

      if (serviceData != null && mounted) {
        print('🔍 DEBUG [_loadServiceFromMySQL]: provider_id = ${serviceData['provider_id']}');
        print('🔍 DEBUG [_loadServiceFromMySQL]: provider_name = ${serviceData['provider_name']}');
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

          // Initialize with first menu item selected by default (only once)
          if (_service!.menuItems.isNotEmpty && !_hasInitializedMenus) {
            _selectedMenuItems = [_service!.menuItems.first];
            _hasInitializedMenus = true;
          }
        });
      }
    } catch (e) {
      print('Error loading service from MySQL: $e');
    }
  }

  Future<void> _loadProviderData() async {
    if (_service?.providerId != null) {
      try {
        final provider = await MySQLService.instance.getProviderById(_service!.providerId!);
        if (mounted) {
          setState(() {
            _providerData = provider;
          });
        }
      } catch (e) {
        print('Error loading provider data: $e');
      }
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
          _averageRating = _calculateAverageRating();
          _reviewCount = _reviews.length;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _reviews = [];
          _averageRating = 0.0;
          _reviewCount = 0;
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

  Future<void> _loadCoupons() async {
    final userId = AuthService.currentUserProviderId;
    if (userId == null) return;

    try {
      final coupons = await MySQLService.instance.getCoupons(userId);
      if (mounted) {
        setState(() {
          _availableCoupons = coupons.map((c) {
            final amount = c['discount_amount'] as int? ?? 0;
            final source = c['source'] as String? ?? '';
            final label = source == 'invite_received'
                ? '招待クーポン ¥$amount OFF'
                : source == 'invite_given'
                    ? '紹介クーポン ¥$amount OFF'
                    : 'クーポン ¥$amount OFF';
            return {
              'id': c['id'].toString(),
              'name': label,
              'discount': amount,
              'code': c['code'],
              'expires_at': c['expires_at'],
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading coupons: $e');
    }
  }

  Future<void> _loadSavedCards() async {
    // 無効なカードデータ(SetupIntent ID)を削除
    final cards = await PaymentMethodService.getSavedCards();
    bool needsCleanup = false;

    // SetupIntent IDで始まるカードを検出
    for (var card in cards) {
      if (card.id.startsWith('seti_')) {
        needsCleanup = true;
        break;
      }
    }

    if (needsCleanup) {
      // 全てクリアして再読み込み
      await PaymentMethodService.clearAllCards();
    }

    // 再度カードを読み込む
    final cleanCards = await PaymentMethodService.getSavedCards();
    final defaultCard = await PaymentMethodService.getDefaultCard();

    setState(() {
      _savedCards = cleanCards;
      _selectedCard = defaultCard;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If service not found, show error
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
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red[50],
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'キャンセルにはキャンセル料が発生しますのでご注意ください',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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

            // Gallery Images
            if (_galleryImages.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ギャラリー',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _galleryImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < _galleryImages.length - 1 ? 12 : 0,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _galleryImages[index],
                                width: 160,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 160,
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 160,
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Location & Date/Time with edit buttons
            _buildEditableInfoSection(
              icon: Icons.location_on,
              title: '場所',
              content: _selectedAddress ?? '住所を入力してください',
              onEdit: _isViewOnly ? null : () => _showLocationEditDialog(),
            ),

            _buildEditableInfoSection(
              icon: Icons.calendar_today,
              title: '日時',
              content: _selectedDate != null && _selectedTimeSlot != null
                  ? '${DateFormat('yyyy年M月d日').format(_selectedDate!)} $_selectedTimeSlot'
                  : '${_service!.date} ${_service!.time}（タップして選択）',
              onEdit: _isViewOnly ? null : () => _showDateTimeEditDialog(),
            ),

            const SizedBox(height: 16),

            // Reviews summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoadingReviews
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _reviews.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.lightGray),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
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
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_averageRating.toStringAsFixed(1)} / 5.0',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$_reviewCount件のレビュー',
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
            ),

            const SizedBox(height: 16),

            // Divider
            Divider(color: Colors.grey[300], height: 1),

            const SizedBox(height: 16),

            // Menu details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'メニュー',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Selected menu items only
                  ..._selectedMenuItems.map((item) => _buildMenuItem(
                        item.name,
                        item.price,
                        item.duration,
                      )),
                  if (!_isViewOnly) ...[
                    const SizedBox(height: 8),
                    // Add menu button
                    GestureDetector(
                      onTap: () => _showAddMenuDialog(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentBlue, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_circle_outline, color: AppColors.accentBlue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'メニューを追加',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 12),

                  // コース費用（メニュー小計）
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'コース費用',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _calculateSubtotal(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 交通費
                  if (_service!.transportationFee > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '交通費',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '¥${_service!.transportationFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 手数料
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '手数料',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _calculateServiceFee(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Points section (only show if not view-only)
            if (!_isViewOnly) ...[
              const SizedBox(height: 16),
              _buildPointsSection(),
            ],

            // Coupon section (only show if not view-only)
            if (!_isViewOnly) ...[
              const SizedBox(height: 16),
              _buildCouponSection(),
            ],

            // Payment method section (disabled for now - requires Customer implementation)
            // if (!_isViewOnly && _savedCards.isNotEmpty) ...[
            //   const SizedBox(height: 16),
            //   _buildPaymentMethodSection(),
            // ],

            // Final total
            if (!_isViewOnly) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryOrange, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '合計金額',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _calculateFinalTotal(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Additional Notes Section (only show if not view-only)
            if (!_isViewOnly) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '追加事項（任意）',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Service details note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 18,
                                  color: AppColors.accentBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '施術内容について',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '「肩が凝っている」など、スタッフへ事前に伝えたいことがありましたらご記入ください',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Visit location note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '訪問先について',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '建物名やホテル名のご記入がない場合、リクエスト承認されない可能性があります。',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Text input field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: TextField(
                        controller: _additionalNotesController,
                        maxLines: 5,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '例：マンション名・部屋番号、施術で気になる箇所など',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Cancellation policy checkbox (only show if not view-only)
            if (!_isViewOnly) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptCancellationPolicy,
                          onChanged: (value) {
                            setState(() {
                              _acceptCancellationPolicy = value ?? false;
                            });
                          },
                          activeColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _showCancellationPolicyDialog();
                          },
                          child: const Text(
                            'キャンセルポリシーに同意します',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Date/time selection warning
              if (_selectedDate == null || _selectedTimeSlot == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '日時を選択してください',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_selectedDate == null || _selectedTimeSlot == null)
                const SizedBox(height: 12),

              // Confirm button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_acceptCancellationPolicy && _selectedDate != null && _selectedTimeSlot != null)
                        ? () {
                            // Handle booking confirmation
                            _showConfirmationDialog();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_acceptCancellationPolicy && _selectedDate != null && _selectedTimeSlot != null)
                          ? AppColors.primaryOrange
                          : Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: const Text(
                      '予約を確定する',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String name, String price, String duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (duration.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (!_isViewOnly) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMenuItems.removeWhere((item) => item.name == name);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.remove_circle_outline,
                  size: 18,
                  color: Colors.red[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<String> _createProviderBooking() async {
    final providerDb = ProviderDatabaseService();
    final userProfile = AuthService.currentUserProfile;

    // Parse price from string (e.g., "¥5,500〜" to 5500)
    int price = 0;
    final priceMatch = RegExp(r'¥([\d,]+)').firstMatch(_service!.price);
    if (priceMatch != null) {
      price = int.parse(priceMatch.group(1)!.replaceAll(',', ''));
    }

    final bookingId = 'booking_${DateTime.now().millisecondsSinceEpoch}';
    final booking = Booking(
      id: bookingId,
      providerId: _service!.providerId!,
      salonId: _service!.salonId!,
      serviceId: _service!.id,
      customerName: userProfile?.name ?? AuthService.currentUser ?? 'ゲストユーザー',
      customerPhone: userProfile?.phone ?? '未登録',
      customerEmail: userProfile?.email ?? '未登録',
      serviceName: _service!.menuItems.isNotEmpty ? _service!.menuItems[0].name : _service!.title,
      bookingDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)), // Use selected date or default to tomorrow
      timeSlot: _selectedTimeSlot ?? _service!.time, // Use selected time slot or service default
      price: price,
      status: 'confirmed',  // Changed to 'confirmed' since payment succeeded
      createdAt: DateTime.now(),
      notes: _additionalNotesController.text.isNotEmpty ? _additionalNotesController.text : null,
    );

    // Add to local database
    providerDb.addBooking(booking);
    print('✅ Created provider booking: ${booking.id} for provider: ${_service!.providerId}');

    // Save to MySQL database
    try {
      // Parse duration from selected menu item (e.g., "60分" -> 60)
      int duration = 60;
      if (_selectedMenuItems.isNotEmpty && _selectedMenuItems[0].duration.isNotEmpty) {
        final durationMatch = RegExp(r'(\d+)').firstMatch(_selectedMenuItems[0].duration);
        if (durationMatch != null) {
          duration = int.parse(durationMatch.group(1)!);
        }
      }

      final bookingData = {
        'id': booking.id,
        'provider_id': booking.providerId,
        'salon_id': booking.salonId,
        'service_id': booking.serviceId,
        'customer_name': booking.customerName,
        'customer_phone': booking.customerPhone,
        'customer_email': booking.customerEmail,
        'user_id': AuthService.currentUser,
        'service_name': booking.serviceName,
        'booking_date': booking.bookingDate.toIso8601String(),
        'time_slot': booking.timeSlot,
        'duration': duration,
        'price': booking.price,
        'status': booking.status,
        'notes': booking.notes,
        'payment_intent_id': _paymentIntentId,
        'stripe_account_id': _stripeAccountId,
        'amount': _paidAmount ?? booking.price,
      };

      await MySQLService.instance.createBooking(bookingData);
      print('✅ Saved booking to MySQL database');

      // Create revenue record
      final revenueId = 'revenue_$bookingId';
      final revenueData = {
        'id': revenueId,
        'provider_id': booking.providerId,
        'booking_id': booking.id,
        'amount': booking.price,
        'date': booking.bookingDate.toIso8601String(),
        'status': 'pending',  // Revenue starts as pending
        'payment_method': 'クレジットカード',
      };

      await MySQLService.instance.createRevenue(revenueData);
      print('✅ Created revenue record for booking: $bookingId');
    } catch (e) {
      print('❌ Error saving booking/revenue to MySQL: $e');
    }

    return booking.id;
  }

  void _showCancellationPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'キャンセルポリシー',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '本会員は、予約開始時刻の180分前まではいつでもケアスタッフへの通知をもって予約をキャンセルできます。\n\n180分前を過ぎた場合、本会員はサービス料の全額をキャンセル料として支払うものとします。',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約確認'),
        content: const Text('この内容で予約を確定しますか？\n\n決済画面に進みます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processPaymentAndBooking();
            },
            child: const Text(
              '決済に進む',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // 決済処理と予約確定
  Future<void> _processPaymentAndBooking() async {
    print('🔵 [Booking] 決済処理開始');
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 最終金額を計算（ポイント・クーポン適用後）
      final finalAmount = _calculateFinalAmountInCents();
      print('   - 最終金額: $finalAmount 円');

      // メタデータを準備
      final metadata = {
        'service_id': _service!.id,
        'service_name': _service!.title,
        'provider_name': _service!.provider,
        'selected_menus': _selectedMenuItems.map((m) => m.name).join(', '),
      };

      // ローディングを閉じる
      Navigator.pop(context);

      print('   - Stripe決済開始');
      // 新しいカードで決済（Direct Charge with Application Fee）
      final paymentResult = await StripeService.processPayment(
        amountInCents: finalAmount,
        providerId: _service!.providerId ?? 'test_provider_001',
        currency: 'jpy',
        metadata: metadata,
      );

      final paymentSuccess = paymentResult['success'] as bool? ?? false;
      print('   - 決済結果: $paymentSuccess');

      if (paymentSuccess) {
        // 決済情報を保存（キャンセル・返金用）
        _paymentIntentId = paymentResult['paymentIntentId'] as String?;
        _stripeAccountId = paymentResult['stripeAccountId'] as String?;
        _paidAmount = finalAmount;
        print('   - Payment Intent ID: $_paymentIntentId');
        print('   - Stripe Account ID: $_stripeAccountId');

        print('   - 決済成功、予約確定処理を開始');
        // 決済成功 → 予約を確定
        await _confirmBooking();
      } else {
        print('   - 決済キャンセル');
        // ユーザーがキャンセルした場合
        _showErrorDialog('決済がキャンセルされました。');
      }
    } catch (e) {
      print('   ❌ 決済エラー: $e');
      // エラー処理
      Navigator.of(context, rootNavigator: true).pop(); // ローディングを閉じる
      _showErrorDialog('決済処理に失敗しました: ${e.toString()}');
    }
  }

  // 最終金額を計算（円単位、決済用）
  int _calculateFinalAmountInCents() {
    int subtotal = _getSubtotalAmount() + (_service?.transportationFee ?? 0);
    int serviceFee = _getServiceFeeAmount();
    int total = subtotal + serviceFee;

    // ポイント割引を適用
    total = total - _usedPoints;

    // クーポン割引を適用
    if (_selectedCoupon != null) {
      final coupon = _availableCoupons.firstWhere((c) => c['id'] == _selectedCoupon);
      if (coupon['discount'] is double) {
        total = (total * (1 - coupon['discount'])).round();
      } else {
        total -= coupon['discount'] as int;
      }
    }

    // 0円以下にならないように
    if (total < 0) total = 0;

    return total;
  }

  // 予約を確定
  Future<void> _confirmBooking() async {
    print('🔵 [Booking] 予約確定処理開始');
    try {
      // 予約履歴に保存
      print('   - 予約履歴に保存中');
      final bookingService = BookingHistoryService();
      bookingService.addBooking(_service!);
      print('   - 予約履歴に保存完了');

      // プロバイダー側の予約を作成
      String? bookingId;
      print('   - プロバイダーID: ${_service!.providerId}');
      print('   - サロンID: ${_service!.salonId}');
      if (_service!.providerId != null && _service!.salonId != null) {
        print('   - プロバイダー予約作成中');
        bookingId = await _createProviderBooking();
        print('   - プロバイダー予約作成完了: $bookingId');
      } else {
        print('   ⚠️ プロバイダーIDまたはサロンIDがnull');
      }

      // クーポンを使用済みにする
      if (_selectedCoupon != null) {
        final userId = AuthService.currentUserProviderId;
        if (userId != null) {
          final couponId = int.tryParse(_selectedCoupon!);
          if (couponId != null) {
            await MySQLService.instance.useCoupon(couponId, userId);
            print('   - クーポン使用済みに更新: $_selectedCoupon');
          }
        }
      }

      // チャットルームを作成
      ChatRoom? chatRoom;
      print('   - チャットルーム作成チェック: bookingId=$bookingId, providerId=${_service!.providerId}');
      if (bookingId != null && _service!.providerId != null) {
        final currentUser = AuthService.currentUser;
        print('   - 現在のユーザー: $currentUser');
        if (currentUser != null) {
          print('   - チャットルーム作成開始');
          final chatService = ChatService();
          chatRoom = await chatService.createChatRoom(
            userId: currentUser,
            providerId: _service!.providerId!,
            providerName: _service!.provider,
            serviceName: _service!.title,
            bookingId: bookingId,
          );
          print('   - チャットルーム作成完了: ${chatRoom.id}');

          // Send notification to provider about new booking
          print('   - プロバイダーへ通知を送信');
          final userProfile = AuthService.currentUserProfile;
          final notificationService = NotificationService();
          await notificationService.notifyProviderNewBooking(
            providerId: _service!.providerId!,
            bookingId: bookingId,
            customerName: userProfile?.name ?? currentUser,
            serviceName: _service!.title,
            bookingDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
            timeSlot: _selectedTimeSlot ?? _service!.time,
          );
          print('   - プロバイダーへの通知送信完了');
        } else {
          print('   ⚠️ currentUserがnull');
        }
      } else {
        print('   ⚠️ チャットルーム作成スキップ: bookingId=$bookingId, providerId=${_service!.providerId}');
      }

      // 成功ダイアログを表示
      if (!mounted) return;

      // Web環境かどうかをチェック
      bool isWeb = identical(0, 0.0);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('予約完了'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('決済が完了し、予約が確定しました。\n\nプロバイダーとのチャットが開始されました。'),
              if (isWeb) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Webアプリのテストモードのため、決済を簡略化しています（Web版非対応の技術のため）',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (chatRoom != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // ダイアログを閉じる
                  // チャットルームに遷移
                  Navigator.pushReplacementNamed(
                    context,
                    '/chat-room',
                    arguments: chatRoom!.id,
                  );
                },
                child: const Text(
                  'チャットを開く',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ダイアログを閉じる
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
              child: Text(
                'ダッシュボードへ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: chatRoom != null ? AppColors.textSecondary : AppColors.primaryOrange,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('予約の保存に失敗しました: ${e.toString()}');
    }
  }

  // エラーダイアログを表示
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('エラー'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoSection({
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accentBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accentBlue, width: 1),
                  ),
                  child: const Text(
                    '編集',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPointsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showPointsDialog(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.stars, color: Colors.amber[700], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ポイント利用',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _usedPoints > 0
                          ? '$_usedPoints ポイント利用中'
                          : '最大利用可能ポイント: $_availablePoints',
                      style: TextStyle(
                        fontSize: 13,
                        color: _usedPoints > 0 ? AppColors.primaryOrange : Colors.grey[600],
                        fontWeight: _usedPoints > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showCouponDialog(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.confirmation_number, color: AppColors.primaryOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'クーポンを使う',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedCoupon != null
                          ? _availableCoupons.firstWhere((c) => c['id'] == _selectedCoupon)['name']
                          : '${_availableCoupons.length}枚利用可能',
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedCoupon != null ? AppColors.primaryOrange : Colors.grey[600],
                        fontWeight: _selectedCoupon != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showPaymentMethodDialog(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card, color: AppColors.accentBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '支払い方法',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedCard != null
                          ? _selectedCard!.displayName
                          : '新しいカードで支払う',
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedCard != null ? AppColors.accentBlue : Colors.grey[600],
                        fontWeight: _selectedCard != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // コース費用のみの小計
  String _calculateSubtotal() {
    int total = 0;
    for (var item in _selectedMenuItems) {
      final priceMatch = RegExp(r'¥([\d,]+)').firstMatch(item.price);
      if (priceMatch != null) {
        total += int.parse(priceMatch.group(1)!.replaceAll(',', ''));
      }
    }
    return '¥${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // コース費用の数値を取得
  int _getSubtotalAmount() {
    int total = 0;
    for (var item in _selectedMenuItems) {
      final priceMatch = RegExp(r'¥([\d,]+)').firstMatch(item.price);
      if (priceMatch != null) {
        total += int.parse(priceMatch.group(1)!.replaceAll(',', ''));
      }
    }
    return total;
  }

  // コース費用 + 交通費
  String _calculateSubtotalWithTransportation() {
    int total = _getSubtotalAmount() + (_service?.transportationFee ?? 0);
    return '¥${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // 手数料（23%）
  String _calculateServiceFee() {
    int subtotal = _getSubtotalAmount() + (_service?.transportationFee ?? 0);
    int serviceFee = (subtotal * 0.23).round();
    return '¥${serviceFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // 手数料の数値を取得
  int _getServiceFeeAmount() {
    int subtotal = _getSubtotalAmount() + (_service?.transportationFee ?? 0);
    return (subtotal * 0.23).round();
  }

  // 最終合計（コース費用 + 交通費 + 手数料 - ポイント - クーポン）
  String _calculateFinalTotal() {
    int subtotal = _getSubtotalAmount() + (_service?.transportationFee ?? 0);
    int serviceFee = _getServiceFeeAmount();
    int total = subtotal + serviceFee;

    // Apply points discount
    total = total - _usedPoints;

    // Apply coupon discount
    if (_selectedCoupon != null) {
      final coupon = _availableCoupons.firstWhere((c) => c['id'] == _selectedCoupon);
      if (coupon['discount'] is double) {
        total = (total * (1 - coupon['discount'])).round();
      } else {
        total -= coupon['discount'] as int;
      }
    }

    // Ensure total never goes below 0
    if (total < 0) total = 0;

    return '¥${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _showLocationEditDialog() {
    final addressController = TextEditingController(text: _selectedAddress ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('場所を編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'サービスを受ける場所を入力してください',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '例：〒100-0001 東京都千代田区千代田1-1 マンション名 101号室',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryOrange),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedAddress = addressController.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDateTimeEditDialog() {
    if (_service?.providerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロバイダー情報が見つかりません')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _DateTimeSelectionDialog(
        providerId: _service!.providerId!,
        onDateTimeSelected: (date, timeSlot) {
          setState(() {
            _selectedDate = date;
            _selectedTimeSlot = timeSlot;
          });
        },
      ),
    );
  }

  void _showAddMenuDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メニューを追加'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _service!.menuItems.length,
            itemBuilder: (context, index) {
              final item = _service!.menuItems[index];
              final isSelected = _selectedMenuItems.any((m) => m.name == item.name);

              return CheckboxListTile(
                title: Text(item.name),
                subtitle: Text('${item.price} • ${item.duration}'),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedMenuItems.add(item);
                    } else {
                      _selectedMenuItems.removeWhere((m) => m.name == item.name);
                    }
                  });
                  Navigator.pop(context);
                },
                activeColor: AppColors.primaryOrange,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showPointsDialog() {
    final TextEditingController pointsController = TextEditingController(
      text: _usedPoints > 0 ? _usedPoints.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ポイント利用'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '利用可能ポイント: $_availablePoints',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '使用するポイント',
                border: const OutlineInputBorder(),
                suffixText: 'ポイント',
                hintText: '0',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              final points = int.tryParse(pointsController.text) ?? 0;
              if (points <= _availablePoints) {
                setState(() {
                  _usedPoints = points;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('利用可能なポイントを超えています')),
                );
              }
            },
            child: const Text('適用'),
          ),
        ],
      ),
    );
  }

  void _showCouponDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クーポンを選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableCoupons.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return RadioListTile<String?>(
                  title: const Text('使用しない'),
                  value: null,
                  groupValue: _selectedCoupon,
                  onChanged: (value) {
                    setState(() {
                      _selectedCoupon = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primaryOrange,
                );
              }

              final coupon = _availableCoupons[index - 1];
              final expiresAt = coupon['expires_at'] as String?;
              final expiresLabel = expiresAt != null ? '有効期限: ${expiresAt.substring(0, 10)}' : '';
              return RadioListTile<String>(
                title: Text(coupon['name']),
                subtitle: Text(expiresLabel),
                value: coupon['id'],
                groupValue: _selectedCoupon,
                onChanged: (value) {
                  setState(() {
                    _selectedCoupon = value;
                  });
                  Navigator.pop(context);
                },
                activeColor: AppColors.primaryOrange,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支払い方法を選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _savedCards.length + 1,
            itemBuilder: (context, index) {
              if (index == _savedCards.length) {
                // 新しいカードで支払うオプション
                return RadioListTile<SavedPaymentMethod?>(
                  title: const Text('新しいカードで支払う'),
                  subtitle: const Text('カード情報を入力します'),
                  value: null,
                  groupValue: _selectedCard,
                  onChanged: (value) {
                    setState(() {
                      _selectedCard = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.accentBlue,
                );
              }

              final card = _savedCards[index];
              return RadioListTile<SavedPaymentMethod>(
                title: Text(card.displayName),
                subtitle: Text('登録日: ${card.createdAt.toString().split(' ')[0]}'),
                value: card,
                groupValue: _selectedCard,
                onChanged: (value) {
                  setState(() {
                    _selectedCard = value;
                  });
                  Navigator.pop(context);
                },
                activeColor: AppColors.accentBlue,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/payment-registration'),
            child: const Text('カードを管理'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

// Date and time selection dialog for booking
class _DateTimeSelectionDialog extends StatefulWidget {
  final String providerId;
  final Function(DateTime, String) onDateTimeSelected;

  const _DateTimeSelectionDialog({
    required this.providerId,
    required this.onDateTimeSelected,
  });

  @override
  State<_DateTimeSelectionDialog> createState() => _DateTimeSelectionDialogState();
}

class _DateTimeSelectionDialogState extends State<_DateTimeSelectionDialog> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<Map<String, dynamic>> _availabilityData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🔍 DEBUG [initState]: Called with providerId = ${widget.providerId}');
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Debug: Check provider ID source
      final providerId = widget.providerId;
      print('🔍 DEBUG: Using providerId = $providerId');
      print('🔍 DEBUG: Current date = ${DateTime.now()}');

      final availability = await MySQLService.instance.getAvailability(providerId);
      print('📅 Loaded availability for $providerId: ${availability.length} slots');

      // Debug: Show all slots received
      for (int i = 0; i < availability.length && i < 5; i++) {
        print('🔍 DEBUG: Slot $i = ${availability[i]}');
      }

      if (availability.isNotEmpty) {
        print('📅 First slot: ${availability[0]}');
      } else {
        print('⚠️ DEBUG: No availability slots found for provider: $providerId');
      }

      if (mounted) {
        setState(() {
          _availabilityData = availability;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading availability: $e');
      print('🔍 DEBUG: Error details - ${e.toString()}');
      print('🔍 DEBUG: Stack trace - ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> _getAvailableTimeSlotsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    print('🔍 DEBUG [_getAvailableTimeSlotsForDate]: Looking for slots on date = $dateStr');
    print('🔍 DEBUG [_getAvailableTimeSlotsForDate]: Total availability data = ${_availabilityData.length} items');

    final filteredSlots = _availabilityData.where((slot) {
      // Handle both string format (yyyy-MM-dd) and ISO format (yyyy-MM-ddT00:00:00.000Z)
      final slotDate = slot['date'] as String;
      final normalizedDate = slotDate.split('T')[0]; // Extract date part only
      final isAvailable = slot['is_available'];
      final matches = normalizedDate == dateStr && (isAvailable == 1 || isAvailable == true);

      print('🔍 DEBUG [Filter]: Slot date=$normalizedDate, looking for=$dateStr, is_available=$isAvailable, matches=$matches');
      return matches;
    }).toList();

    print('🔍 DEBUG [_getAvailableTimeSlotsForDate]: Found ${filteredSlots.length} matching slots');

    return filteredSlots.map((slot) {
          final timeSlot = slot['time_slot'] as String;
          // Convert "09:00-10:00" format to "09:00" (just show start time)
          if (timeSlot.contains('-')) {
            return timeSlot.split('-')[0];
          }
          return timeSlot;
        })
        .toList()
      ..sort();
  }

  bool _hasAvailabilityForDate(DateTime date) {
    return _getAvailableTimeSlotsForDate(date).isNotEmpty;
  }

  void _previousMonth() {
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    if (newMonth.isBefore(currentMonth)) {
      return;
    }

    setState(() {
      _selectedMonth = newMonth;
      _selectedDate = null;
      _selectedTimeSlot = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _selectedDate = null;
      _selectedTimeSlot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '日時を選択',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Month selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        DateFormat('yyyy年 M月').format(_selectedMonth),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Calendar grid
                  _buildCalendar(),
                  const SizedBox(height: 20),

                  // Time slots
                  if (_selectedDate != null) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      '時間帯を選択',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSlots(),
                    const SizedBox(height: 20),
                  ],

                  // Confirm button
                  if (_selectedDate != null && _selectedTimeSlot != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onDateTimeSelected(_selectedDate!, _selectedTimeSlot!);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '${DateFormat('M月d日').format(_selectedDate!)} ${_selectedTimeSlot!} を確定',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['日', '月', '火', '水', '木', '金', '土']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar days
        for (int week = 0; week < 6; week++)
          if (week * 7 < daysInMonth + startWeekday)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = week * 7 + dayIndex - startWeekday + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox());
                  }

                  final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                  final isPastDate = date.isBefore(today);
                  final hasAvailability = _hasAvailabilityForDate(date);
                  final isSelected = _selectedDate != null &&
                      _selectedDate!.year == date.year &&
                      _selectedDate!.month == date.month &&
                      _selectedDate!.day == date.day;

                  return Expanded(
                    child: GestureDetector(
                      onTap: (isPastDate || !hasAvailability)
                          ? null
                          : () {
                              setState(() {
                                _selectedDate = date;
                                _selectedTimeSlot = null;
                              });
                            },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPastDate
                              ? Colors.grey[200]
                              : isSelected
                                  ? AppColors.accentBlue
                                  : hasAvailability
                                      ? Colors.green[50]
                                      : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentBlue
                                : hasAvailability
                                    ? Colors.green[300]!
                                    : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isPastDate
                                  ? Colors.grey[400]
                                  : isSelected
                                      ? Colors.white
                                      : hasAvailability
                                          ? AppColors.textPrimary
                                          : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    final availableSlots = _getAvailableTimeSlotsForDate(_selectedDate!);

    if (availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'この日は空きがありません',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableSlots.map((timeSlot) {
        final isSelected = _selectedTimeSlot == timeSlot;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimeSlot = timeSlot;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryOrange : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primaryOrange : AppColors.lightGray,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              timeSlot,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
