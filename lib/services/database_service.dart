class ServiceModel {
  final String id;
  final String title;
  final String provider;
  final String providerTitle;
  final String price;
  final String rating;
  final String reviews;
  final String category;
  final String subcategory;
  final String location;
  final String address;
  final String date;
  final String time;
  final List<MenuItem> menuItems;
  final String totalPrice;
  final List<ServiceReview> reviewsList;
  final String description;
  final String? providerId;  // Provider ID for linking bookings
  final String? salonId;     // Salon ID for linking bookings
  final String serviceAreas; // 提供エリア
  final int transportationFee; // 交通費

  ServiceModel({
    required this.id,
    required this.title,
    required this.provider,
    required this.providerTitle,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.category,
    required this.subcategory,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.menuItems,
    required this.totalPrice,
    required this.reviewsList,
    required this.description,
    this.providerId,
    this.salonId,
    this.serviceAreas = '',
    this.transportationFee = 0,
  });
}

class MenuItem {
  final String name;
  final String price;
  final String duration;
  final String description;
  final List<String> durationOptions; // サービス時間オプション

  MenuItem({
    required this.name,
    required this.price,
    this.duration = '',
    this.description = '',
    this.durationOptions = const ['60'],
  });
}

class ServiceReview {
  final String userName;
  final double rating;
  final String comment;
  final String date;

  ServiceReview({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static final List<ServiceModel> _services = [
    // 1. まつげエクステ
    ServiceModel(
      id: '1',
      title: 'まつげエクステ　出張施術',
      provider: '佐藤 美咲',
      providerTitle: 'プロアイリスト',
      price: '60分 ¥5,000〜',
      rating: '4.9',
      reviews: '128',
      category: '美容・リラクゼーション',
      subcategory: 'まつげ',
      location: '東京都',
      address: '',
      date: '',
      time: '',
      description: 'ご自宅で受けられるまつげエクステ。自然な仕上がりから華やかなデザインまで、お好みに合わせて施術します。プレミアムラッシュ使用で持続力抜群。',
      providerId: 'test_provider_001',
      salonId: null,
      serviceAreas: '東京都, 神奈川県',
      transportationFee: 1000,
      menuItems: [
        MenuItem(
          name: 'ナチュラルコース',
          price: '¥5,000',
          duration: '60分',
          description: '80本程度の自然な仕上がり',
          durationOptions: ['60'],
        ),
        MenuItem(
          name: 'ボリュームコース',
          price: '¥6,500',
          duration: '90分',
          description: '120本の華やかな仕上がり',
          durationOptions: ['90'],
        ),
      ],
      totalPrice: '60分 ¥5,000〜',
      reviewsList: [
        ServiceReview(
          userName: '田中 愛美',
          rating: 5.0,
          comment: '自宅で受けられるので小さい子がいても安心です。仕上がりも綺麗で大満足！',
          date: '2025年10月15日',
        ),
        ServiceReview(
          userName: '山田 麻衣',
          rating: 4.5,
          comment: 'デザインの提案も的確で、理想通りの目元になりました。',
          date: '2025年10月12日',
        ),
      ],
    ),

    // 2. ジェルネイル
    ServiceModel(
      id: '2',
      title: 'ジェルネイル　出張施術',
      provider: '鈴木 彩',
      providerTitle: 'ネイリスト',
      price: '60分 ¥5,500〜',
      rating: '4.8',
      reviews: '156',
      category: '美容・リラクゼーション',
      subcategory: 'ネイル',
      location: '東京都',
      address: '',
      date: '',
      time: '',
      description: 'お好きな場所でネイルケア。トレンドデザインからシンプルまで、高品質なジェルで美しい仕上がりが長持ちします。',
      providerId: 'test_provider_002',
      salonId: null,
      serviceAreas: '東京都, 埼玉県',
      transportationFee: 800,
      menuItems: [
        MenuItem(
          name: 'ワンカラー',
          price: '¥5,500',
          duration: '60分',
          description: 'シンプルで上品な単色ネイル',
          durationOptions: ['60'],
        ),
        MenuItem(
          name: 'デザインネイル',
          price: '¥7,500',
          duration: '90分',
          description: 'アート込みのデザインネイル',
          durationOptions: ['90'],
        ),
      ],
      totalPrice: '60分 ¥5,500〜',
      reviewsList: [
        ServiceReview(
          userName: '佐々木 美緒',
          rating: 5.0,
          comment: 'デザインのセンスが素晴らしい！持ちも良くて大満足です。',
          date: '2025年10月14日',
        ),
        ServiceReview(
          userName: '高橋 真由',
          rating: 4.5,
          comment: '自宅で受けられるのでリラックスできました。また利用します。',
          date: '2025年10月10日',
        ),
      ],
    ),

    // 3. ベビーシッター
    ServiceModel(
      id: '3',
      title: 'ベビーシッター',
      provider: '木村 優子',
      providerTitle: '保育士',
      price: '2時間 ¥3,000〜',
      rating: '4.9',
      reviews: '234',
      category: '子育て・家事サポート',
      subcategory: '保育',
      location: '東京都',
      address: '',
      date: '',
      time: '',
      description: '保育士資格を持つプロのシッターがお子様をご自宅で安全にお預かり。急な用事や息抜きの時間に安心してご利用いただけます。',
      providerId: 'test_provider_003',
      salonId: null,
      serviceAreas: '東京都, 千葉県',
      transportationFee: 500,
      menuItems: [
        MenuItem(
          name: '2時間コース',
          price: '¥3,000',
          duration: '2時間',
          description: '短時間のお預かり',
          durationOptions: ['120'],
        ),
        MenuItem(
          name: '3時間コース',
          price: '¥4,500',
          duration: '3時間',
          description: 'ゆとりのお預かり',
          durationOptions: ['180'],
        ),
      ],
      totalPrice: '2時間 ¥3,000〜',
      reviewsList: [
        ServiceReview(
          userName: '内田 直美',
          rating: 5.0,
          comment: '保育士さんなので安心してお願いできました。子供もとても楽しそうでした！',
          date: '2025年10月15日',
        ),
        ServiceReview(
          userName: '野口 祐子',
          rating: 4.5,
          comment: '急な用事でお願いしましたが、丁寧に対応してくださいました。',
          date: '2025年10月11日',
        ),
      ],
    ),

    // 4. 家事代行
    ServiceModel(
      id: '4',
      title: '家事代行サービス',
      provider: '小林 真理',
      providerTitle: '家事代行スタッフ',
      price: '2時間 ¥4,000〜',
      rating: '4.7',
      reviews: '189',
      category: '子育て・家事サポート',
      subcategory: '家事',
      location: '神奈川県',
      address: '',
      date: '',
      time: '',
      description: '掃除、洗濯、片付けなどの日常家事をプロがお手伝い。忙しい毎日に余裕を作ります。',
      providerId: 'test_provider_004',
      salonId: null,
      serviceAreas: '神奈川県, 東京都',
      transportationFee: 1000,
      menuItems: [
        MenuItem(
          name: '2時間コース',
          price: '¥4,000',
          duration: '2時間',
          description: '基本的な家事サポート',
          durationOptions: ['120'],
        ),
        MenuItem(
          name: '3時間コース',
          price: '¥6,000',
          duration: '3時間',
          description: 'じっくり丁寧な家事サポート',
          durationOptions: ['180'],
        ),
      ],
      totalPrice: '2時間 ¥4,000〜',
      reviewsList: [
        ServiceReview(
          userName: '増田 由紀',
          rating: 5.0,
          comment: 'とても丁寧に掃除してくださいました。隅々まで綺麗になって感動です！',
          date: '2025年10月14日',
        ),
        ServiceReview(
          userName: '武田 亜紀',
          rating: 4.5,
          comment: '仕事で疲れている時に助かります。洗濯物も綺麗に畳んでくださいました。',
          date: '2025年10月10日',
        ),
      ],
    ),

    // 5. パーソナルトレーニング
    ServiceModel(
      id: '5',
      title: 'パーソナルトレーニング',
      provider: '伊藤 健太',
      providerTitle: 'パーソナルトレーナー',
      price: '60分 ¥6,000〜',
      rating: '4.8',
      reviews: '95',
      category: '美容・リラクゼーション',
      subcategory: 'フィットネス',
      location: '東京都',
      address: '',
      date: '',
      time: '',
      description: 'ご自宅や公園でのパーソナルトレーニング。あなたの目標に合わせたメニューで効果的にボディメイク。',
      providerId: 'test_provider_005',
      salonId: null,
      serviceAreas: '東京都',
      transportationFee: 500,
      menuItems: [
        MenuItem(
          name: '60分コース',
          price: '¥6,000',
          duration: '60分',
          description: '基本的なトレーニング',
          durationOptions: ['60'],
        ),
        MenuItem(
          name: '90分コース',
          price: '¥9,000',
          duration: '90分',
          description: 'しっかりトレーニング',
          durationOptions: ['90'],
        ),
      ],
      totalPrice: '60分 ¥6,000〜',
      reviewsList: [
        ServiceReview(
          userName: '山田 太郎',
          rating: 5.0,
          comment: '自宅でトレーニングできるのが便利！効果も実感できています。',
          date: '2025年10月13日',
        ),
        ServiceReview(
          userName: '佐藤 花子',
          rating: 4.5,
          comment: '丁寧な指導で続けやすいです。体が引き締まってきました。',
          date: '2025年10月09日',
        ),
      ],
    ),
  ];

  List<ServiceModel> getAllServices() {
    return List.from(_services);
  }

  // Get service by ID
  ServiceModel? getServiceById(String id) {
    try {
      return _services.firstWhere((service) => service.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get services by category
  List<ServiceModel> getServicesByCategory(String category) {
    return _services.where((service) => service.category == category).toList();
  }

  // Get services by subcategory
  List<ServiceModel> getServicesBySubcategory(String subcategory) {
    return _services
        .where((service) => service.subcategory == subcategory)
        .toList();
  }

  // Get services by location
  List<ServiceModel> getServicesByLocation(String location) {
    return _services.where((service) => service.location == location).toList();
  }

  // Filter services
  List<ServiceModel> filterServices({
    String? category,
    String? subcategory,
    String? location,
    String? serviceArea,
  }) {
    List<ServiceModel> filtered = List.from(_services);

    if (category != null) {
      filtered =
          filtered.where((service) => service.category == category).toList();
    }

    if (subcategory != null) {
      filtered = filtered
          .where((service) => service.subcategory == subcategory)
          .toList();
    }

    if (location != null) {
      filtered =
          filtered.where((service) => service.location == location).toList();
    }

    // Filter by service area (提供エリア)
    if (serviceArea != null && serviceArea.isNotEmpty) {
      filtered = filtered.where((service) {
        return service.serviceAreas.contains(serviceArea);
      }).toList();
    }

    return filtered;
  }

  // Add new service (for provider-created services)
  void addService(ServiceModel service) {
    _services.add(service);
  }

  // Remove service
  void removeService(String serviceId) {
    _services.removeWhere((service) => service.id == serviceId);
  }
}
