import '../services/database_service.dart';

// Provider Profile Model
class ProviderProfile {
  final String id;
  final String name;
  final String title;
  final String email;
  final String phone;
  final String bio;
  final String profileImageUrl;
  final bool isVerified;
  final String verificationStatus; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;

  ProviderProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.phone,
    required this.bio,
    this.profileImageUrl = '',
    this.isVerified = false,
    this.verificationStatus = 'pending',
    required this.createdAt,
  });
}

// Salon Information Model
class SalonInfo {
  final String id;
  final String providerId;
  final String salonName;
  final String category;
  final List<String> subcategories;
  final String prefecture;
  final String city;
  final String address;
  final String building;
  final String description;
  final List<String> imageUrls;
  final Map<String, String> businessHours;
  final bool homeVisit;
  final DateTime createdAt;
  // Listing information fields
  final String? tagline;
  final String? detailedDescription;
  final String? facilities;
  final String? accessInfo;
  final String? mainImageUrl;
  final List<String> galleryImageUrls;

  SalonInfo({
    required this.id,
    required this.providerId,
    required this.salonName,
    required this.category,
    required this.subcategories,
    required this.prefecture,
    required this.city,
    required this.address,
    this.building = '',
    required this.description,
    this.imageUrls = const [],
    required this.businessHours,
    this.homeVisit = false,
    required this.createdAt,
    this.tagline,
    this.detailedDescription,
    this.facilities,
    this.accessInfo,
    this.mainImageUrl,
    this.galleryImageUrls = const [],
  });
}

// Service Menu Model for Providers
class ProviderServiceMenu {
  final String id;
  final String providerId;
  final String salonId;
  final String menuName;
  final String description;
  final int price;
  final int duration; // in minutes
  final String category;
  final bool isActive;
  final DateTime createdAt;

  ProviderServiceMenu({
    required this.id,
    required this.providerId,
    required this.salonId,
    required this.menuName,
    required this.description,
    required this.price,
    required this.duration,
    required this.category,
    this.isActive = true,
    required this.createdAt,
  });

  // Convert to MenuItem for ServiceModel
  MenuItem toMenuItem() {
    return MenuItem(
      name: menuName,
      price: '¥${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
      duration: '${duration}分',
      description: description,
    );
  }
}

// Bank Account Info Model
class BankAccountInfo {
  final String providerId;
  final String bankName;
  final String branchName;
  final String accountType; // 'normal', 'savings'
  final String accountNumber;
  final String accountHolderName;
  final bool isVerified;

  BankAccountInfo({
    required this.providerId,
    required this.bankName,
    required this.branchName,
    required this.accountType,
    required this.accountNumber,
    required this.accountHolderName,
    this.isVerified = false,
  });
}

// Identity Verification Model
class IdentityVerification {
  final String providerId;
  final String idType; // 'license', 'passport', 'mynumber'
  final String idImageUrl;
  final String verificationStatus; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final DateTime? approvedAt;
  final String? rejectionReason;

  IdentityVerification({
    required this.providerId,
    required this.idType,
    required this.idImageUrl,
    this.verificationStatus = 'pending',
    required this.submittedAt,
    this.approvedAt,
    this.rejectionReason,
  });
}

// Booking Model
class Booking {
  final String id;
  final String providerId;
  final String salonId;
  final String serviceId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String serviceName;
  final DateTime bookingDate;
  final String timeSlot;
  final int price;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime createdAt;
  final String? notes;

  Booking({
    required this.id,
    required this.providerId,
    required this.salonId,
    required this.serviceId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.serviceName,
    required this.bookingDate,
    required this.timeSlot,
    required this.price,
    required this.status,
    required this.createdAt,
    this.notes,
  });
}

// Revenue Record Model
class RevenueRecord {
  final String id;
  final String providerId;
  final String bookingId;
  final int amount;
  final DateTime date;
  final String status; // 'pending', 'paid'
  final String paymentMethod;

  RevenueRecord({
    required this.id,
    required this.providerId,
    required this.bookingId,
    required this.amount,
    required this.date,
    required this.status,
    required this.paymentMethod,
  });
}

// Provider Database Service
class ProviderDatabaseService {
  static final ProviderDatabaseService _instance = ProviderDatabaseService._internal();
  factory ProviderDatabaseService() => _instance;
  ProviderDatabaseService._internal() {
    _initializeTestData();
  }

  final Map<String, ProviderProfile> _providers = {};
  final Map<String, SalonInfo> _salons = {};
  final Map<String, List<ProviderServiceMenu>> _providerMenus = {};
  final Map<String, BankAccountInfo> _bankAccounts = {};
  final Map<String, IdentityVerification> _verifications = {};
  final Map<String, List<Booking>> _bookings = {};
  final Map<String, List<RevenueRecord>> _revenues = {};

  // Initialize test data for test user
  void _initializeTestData() {
    // Create test provider profile
    final testProvider = ProviderProfile(
      id: 'test_provider_001',
      name: 'テスト 太郎',
      title: 'プロマッサージ師',
      email: 'test@celesmile.com',
      phone: '090-1234-5678',
      bio: 'テストユーザーのプロフィールです。10年以上の経験を持つプロのマッサージ師です。',
      profileImageUrl: '',
      isVerified: true,
      verificationStatus: 'approved',
      createdAt: DateTime.now(),
    );
    _providers['test_provider_001'] = testProvider;

    // Create test salon
    final testSalon = SalonInfo(
      id: 'test_salon_001',
      providerId: 'test_provider_001',
      salonName: 'テストマッサージサロン',
      category: '美容・リラクゼーション',
      subcategories: ['マッサージ'],
      prefecture: '東京都',
      city: '渋谷区',
      address: '恵比寿1-2-3',
      building: 'テストビル 3F',
      description: 'リラックスできる癒しの空間で、本格的なマッサージをご提供します。',
      businessHours: {
        '月': '10:00-20:00',
        '火': '10:00-20:00',
        '水': '10:00-20:00',
        '木': '10:00-20:00',
        '金': '10:00-20:00',
        '土': '10:00-18:00',
        '日': '休業',
      },
      homeVisit: true,
      createdAt: DateTime.now(),
      tagline: '心と体をリフレッシュ',
      detailedDescription: '経験豊富なセラピストによる本格的なマッサージで、日頃の疲れを癒します。',
      facilities: 'プライベート個室、シャワー完備、無料Wi-Fi',
      accessInfo: 'JR恵比寿駅東口より徒歩5分',
      mainImageUrl: 'test_main_image.jpg',
      galleryImageUrls: [],
    );
    _salons['test_salon_001'] = testSalon;

    // Create test menus
    final testMenus = [
      ProviderServiceMenu(
        id: 'test_menu_001',
        providerId: 'test_provider_001',
        salonId: 'test_salon_001',
        menuName: 'リラックスマッサージ 60分',
        description: '全身をほぐす基本コース',
        price: 5500,
        duration: 60,
        category: 'マッサージ',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      ProviderServiceMenu(
        id: 'test_menu_002',
        providerId: 'test_provider_001',
        salonId: 'test_salon_001',
        menuName: 'ディープティシューマッサージ 90分',
        description: '深層筋までしっかりほぐす本格コース',
        price: 8000,
        duration: 90,
        category: 'マッサージ',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
    _providerMenus['test_provider_001'] = testMenus;

    // Create bank account info
    final testBankAccount = BankAccountInfo(
      providerId: 'test_provider_001',
      bankName: 'テスト銀行',
      branchName: '渋谷支店',
      accountType: 'normal',
      accountNumber: '1234567',
      accountHolderName: 'テスト タロウ',
      isVerified: true,
    );
    _bankAccounts['test_provider_001'] = testBankAccount;

    // Create approved verification
    final testVerification = IdentityVerification(
      providerId: 'test_provider_001',
      idType: 'license',
      idImageUrl: 'test_license.jpg',
      verificationStatus: 'approved',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      approvedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    _verifications['test_provider_001'] = testVerification;

    // Create sample bookings
    final testBookings = [
      Booking(
        id: 'booking_001',
        providerId: 'test_provider_001',
        salonId: 'test_salon_001',
        serviceId: 'test_menu_001',
        customerName: 'テスト ユーザー',
        customerPhone: '080-1234-5678',
        customerEmail: 'user@celesmile.com',
        serviceName: 'リラックスマッサージ 60分',
        bookingDate: DateTime.now().add(const Duration(days: 2)),
        timeSlot: '14:00 - 15:00',
        price: 5500,
        status: 'confirmed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'よろしくお願いします',
      ),
      Booking(
        id: 'booking_002',
        providerId: 'test_provider_001',
        salonId: 'test_salon_001',
        serviceId: 'test_menu_002',
        customerName: '山田 花子',
        customerPhone: '090-9876-5432',
        customerEmail: 'hanako@example.com',
        serviceName: 'ディープティシューマッサージ 90分',
        bookingDate: DateTime.now().add(const Duration(days: 5)),
        timeSlot: '16:00 - 17:30',
        price: 8000,
        status: 'pending',
        createdAt: DateTime.now(),
        notes: '肩と背中を重点的にお願いします',
      ),
      Booking(
        id: 'booking_003',
        providerId: 'test_provider_001',
        salonId: 'test_salon_001',
        serviceId: 'test_menu_001',
        customerName: '佐藤 太郎',
        customerPhone: '070-1111-2222',
        customerEmail: 'taro@example.com',
        serviceName: 'リラックスマッサージ 60分',
        bookingDate: DateTime.now().subtract(const Duration(days: 3)),
        timeSlot: '10:00 - 11:00',
        price: 5500,
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
    _bookings['test_provider_001'] = testBookings;

    // Create revenue records
    final testRevenues = [
      RevenueRecord(
        id: 'revenue_001',
        providerId: 'test_provider_001',
        bookingId: 'booking_003',
        amount: 5500,
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: 'paid',
        paymentMethod: 'クレジットカード',
      ),
      RevenueRecord(
        id: 'revenue_002',
        providerId: 'test_provider_001',
        bookingId: 'booking_001',
        amount: 5500,
        date: DateTime.now().add(const Duration(days: 2)),
        status: 'pending',
        paymentMethod: 'クレジットカード',
      ),
    ];
    _revenues['test_provider_001'] = testRevenues;

    // Publish test service to main dashboard
    publishServiceToMainDatabase('test_provider_001', 'test_salon_001');
  }

  // Provider Profile Methods
  String createProvider(ProviderProfile provider) {
    _providers[provider.id] = provider;
    return provider.id;
  }

  ProviderProfile? getProvider(String providerId) {
    return _providers[providerId];
  }

  void updateProvider(String providerId, ProviderProfile provider) {
    _providers[providerId] = provider;
  }

  List<ProviderProfile> getAllProviders() {
    return List.from(_providers.values);
  }

  // Salon Methods
  String createSalon(SalonInfo salon) {
    _salons[salon.id] = salon;
    return salon.id;
  }

  SalonInfo? getSalon(String salonId) {
    return _salons[salonId];
  }

  List<SalonInfo> getSalonsByProvider(String providerId) {
    return _salons.values.where((salon) => salon.providerId == providerId).toList();
  }

  void updateSalon(String salonId, SalonInfo salon) {
    _salons[salonId] = salon;
  }

  // Menu Methods
  String addMenu(ProviderServiceMenu menu) {
    if (!_providerMenus.containsKey(menu.providerId)) {
      _providerMenus[menu.providerId] = [];
    }
    _providerMenus[menu.providerId]!.add(menu);
    return menu.id;
  }

  List<ProviderServiceMenu> getMenusByProvider(String providerId) {
    return _providerMenus[providerId] ?? [];
  }

  List<ProviderServiceMenu> getMenusBySalon(String salonId) {
    List<ProviderServiceMenu> allMenus = [];
    _providerMenus.values.forEach((menuList) {
      allMenus.addAll(menuList.where((menu) => menu.salonId == salonId));
    });
    return allMenus;
  }

  void updateMenu(String menuId, ProviderServiceMenu menu) {
    if (_providerMenus.containsKey(menu.providerId)) {
      final index = _providerMenus[menu.providerId]!.indexWhere((m) => m.id == menuId);
      if (index != -1) {
        _providerMenus[menu.providerId]![index] = menu;
      }
    }
  }

  void deleteMenu(String providerId, String menuId) {
    if (_providerMenus.containsKey(providerId)) {
      _providerMenus[providerId]!.removeWhere((m) => m.id == menuId);
    }
  }

  // Bank Account Methods
  void saveBankAccount(BankAccountInfo bankAccount) {
    _bankAccounts[bankAccount.providerId] = bankAccount;
  }

  BankAccountInfo? getBankAccount(String providerId) {
    return _bankAccounts[providerId];
  }

  // Identity Verification Methods
  void submitVerification(IdentityVerification verification) {
    _verifications[verification.providerId] = verification;
  }

  IdentityVerification? getVerification(String providerId) {
    return _verifications[providerId];
  }

  void updateVerificationStatus(String providerId, String status, {String? rejectionReason}) {
    if (_verifications.containsKey(providerId)) {
      final verification = _verifications[providerId]!;
      _verifications[providerId] = IdentityVerification(
        providerId: verification.providerId,
        idType: verification.idType,
        idImageUrl: verification.idImageUrl,
        verificationStatus: status,
        submittedAt: verification.submittedAt,
        approvedAt: status == 'approved' ? DateTime.now() : null,
        rejectionReason: rejectionReason,
      );

      // Update provider verification status
      if (status == 'approved' && _providers.containsKey(providerId)) {
        final provider = _providers[providerId]!;
        _providers[providerId] = ProviderProfile(
          id: provider.id,
          name: provider.name,
          title: provider.title,
          email: provider.email,
          phone: provider.phone,
          bio: provider.bio,
          profileImageUrl: provider.profileImageUrl,
          isVerified: true,
          verificationStatus: 'approved',
          createdAt: provider.createdAt,
        );
      }
    }
  }

  // Convert Provider Services to Main Database
  void publishServiceToMainDatabase(String providerId, String salonId) {
    final salon = _salons[salonId];
    final provider = _providers[providerId];
    final menus = getMenusBySalon(salonId);

    if (salon == null || provider == null || menus.isEmpty) return;

    // Create a ServiceModel and add to main database
    final serviceId = DateTime.now().millisecondsSinceEpoch.toString();

    final service = ServiceModel(
      id: serviceId,
      title: salon.salonName,
      provider: provider.name,
      providerTitle: provider.title,
      price: menus.isNotEmpty ? '¥${menus[0].price}〜' : '¥0',
      rating: '5.0',
      reviews: '0',
      category: salon.category,
      subcategory: salon.subcategories.isNotEmpty ? salon.subcategories[0] : '',
      location: salon.prefecture,
      address: '${salon.prefecture}${salon.city}${salon.address}',
      date: DateTime.now().add(const Duration(days: 1)).toString().substring(0, 10),
      time: '10:00 - 18:00',
      description: salon.description,
      menuItems: menus.map((menu) => menu.toMenuItem()).toList(),
      totalPrice: menus.isNotEmpty ? '¥${menus[0].price}〜' : '¥0',
      reviewsList: [],
      providerId: providerId,  // Add provider ID for booking linking
      salonId: salonId,  // Add salon ID for booking linking
    );

    // Add to the main database
    _addServiceToMainDatabase(service);
  }

  // Private method to add service to main database
  void _addServiceToMainDatabase(ServiceModel service) {
    // Add the service to the main database using the public method
    final db = DatabaseService();
    db.addService(service);
  }

  // Get all published services by provider
  List<ServiceModel> getPublishedServicesByProvider(String providerId) {
    final salons = getSalonsByProvider(providerId);
    final db = DatabaseService();
    final allServices = db.getAllServices();

    return allServices.where((service) {
      return salons.any((salon) => salon.salonName == service.title);
    }).toList();
  }

  // Booking Methods
  List<Booking> getBookingsByProvider(String providerId) {
    return _bookings[providerId] ?? [];
  }

  void addBooking(Booking booking) {
    if (!_bookings.containsKey(booking.providerId)) {
      _bookings[booking.providerId] = [];
    }
    _bookings[booking.providerId]!.add(booking);

    // Also add revenue record if payment is confirmed
    if (booking.status == 'confirmed' || booking.status == 'completed') {
      addRevenueRecord(RevenueRecord(
        id: 'revenue_${booking.id}',
        providerId: booking.providerId,
        bookingId: booking.id,
        amount: booking.price,
        date: booking.bookingDate,
        status: booking.status == 'completed' ? 'paid' : 'pending',
        paymentMethod: 'クレジットカード',
      ));
    }
  }

  void updateBookingStatus(String providerId, String bookingId, String newStatus) {
    if (_bookings.containsKey(providerId)) {
      final index = _bookings[providerId]!.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        final booking = _bookings[providerId]![index];
        _bookings[providerId]![index] = Booking(
          id: booking.id,
          providerId: booking.providerId,
          salonId: booking.salonId,
          serviceId: booking.serviceId,
          customerName: booking.customerName,
          customerPhone: booking.customerPhone,
          customerEmail: booking.customerEmail,
          serviceName: booking.serviceName,
          bookingDate: booking.bookingDate,
          timeSlot: booking.timeSlot,
          price: booking.price,
          status: newStatus,
          createdAt: booking.createdAt,
          notes: booking.notes,
        );
      }
    }
  }

  // Revenue Methods
  List<RevenueRecord> getRevenuesByProvider(String providerId) {
    return _revenues[providerId] ?? [];
  }

  void addRevenueRecord(RevenueRecord revenue) {
    if (!_revenues.containsKey(revenue.providerId)) {
      _revenues[revenue.providerId] = [];
    }
    _revenues[revenue.providerId]!.add(revenue);
  }

  // Get revenue summary
  Map<String, dynamic> getRevenueSummary(String providerId) {
    final revenues = getRevenuesByProvider(providerId);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    int thisMonthTotal = 0;
    int pendingTotal = 0;
    int paidTotal = 0;

    for (var revenue in revenues) {
      // This month's revenue
      if (revenue.date.year == currentMonth.year && revenue.date.month == currentMonth.month) {
        thisMonthTotal += revenue.amount;
      }

      // Pending vs paid
      if (revenue.status == 'pending') {
        pendingTotal += revenue.amount;
      } else if (revenue.status == 'paid') {
        paidTotal += revenue.amount;
      }
    }

    return {
      'thisMonthTotal': thisMonthTotal,
      'pendingTotal': pendingTotal,
      'paidTotal': paidTotal,
      'totalRevenue': pendingTotal + paidTotal,
    };
  }
}
