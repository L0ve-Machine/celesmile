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
  });
}

class MenuItem {
  final String name;
  final String price;
  final String duration;
  final String description;

  MenuItem({
    required this.name,
    required this.price,
    this.duration = '',
    this.description = '',
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
    // 美容・リラクゼーション - まつげ
    ServiceModel(
      id: '1',
      title: 'まつげエクステ',
      provider: '佐藤 美咲',
      providerTitle: 'プロアイリスト',
      price: '¥6,500',
      rating: '4.8',
      reviews: '95',
      category: '美容・リラクゼーション',
      subcategory: 'まつげ',
      location: '東京都',
      address: '東京都渋谷区恵比寿2-5-8',
      date: '2025年10月18日（土）',
      time: '10:00 - 11:30',
      description: '自然な仕上がりから華やかなデザインまで対応。持続力の高いプレミアムラッシュを使用しています。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'ボリュームラッシュ（120本）', price: '¥6,500', duration: '90分'),
      ],
      totalPrice: '¥6,500',
      reviewsList: [
        ServiceReview(
          userName: '松本 愛',
          rating: 5.0,
          comment: '仕上がりがとても自然で、持ちも良いです。佐藤さんの技術は素晴らしいです！',
          date: '2025年10月11日',
        ),
        ServiceReview(
          userName: '井上 舞',
          rating: 4.5,
          comment: 'デザインの相談にも丁寧に乗っていただき、理想通りの仕上がりになりました。',
          date: '2025年10月09日',
        ),
        ServiceReview(
          userName: '加藤 美香',
          rating: 5.0,
          comment: '何度もリピートしています。毎回満足の仕上がりです。',
          date: '2025年10月04日',
        ),
      ],
    ),
    ServiceModel(
      id: '2',
      title: 'まつげパーマ',
      provider: '田中 結衣',
      providerTitle: 'ビューティーアドバイザー',
      price: '¥5,000',
      rating: '4.7',
      reviews: '82',
      category: '美容・リラクゼーション',
      subcategory: 'まつげ',
      location: '神奈川県',
      address: '神奈川県横浜市西区みなとみらい3-1-1',
      date: '2025年10月19日（日）',
      time: '14:00 - 15:00',
      description: 'まつげを傷めにくい薬剤を使用した優しいパーマ。自然な上向きカールが長持ちします。',
      providerId: 'test_provider_002',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'まつげパーマ', price: '¥5,000', duration: '60分'),
      ],
      totalPrice: '¥5,000',
      reviewsList: [
        ServiceReview(
          userName: '高橋 由美',
          rating: 5.0,
          comment: 'パーマのカール具合が完璧でした。メイクの時間が短縮できて助かります。',
          date: '2025年10月13日',
        ),
        ServiceReview(
          userName: '中島 恵',
          rating: 4.5,
          comment: '丁寧な施術で安心できました。カールの持ちも良いです。',
          date: '2025年10月07日',
        ),
        ServiceReview(
          userName: '森 さくら',
          rating: 4.5,
          comment: '自然な仕上がりで気に入りました。また利用します。',
          date: '2025年10月02日',
        ),
      ],
    ),

    // 美容・リラクゼーション - ネイル
    ServiceModel(
      id: '3',
      title: 'ネイルアート',
      provider: '鈴木 彩',
      providerTitle: 'ネイリスト',
      price: '¥7,500',
      rating: '4.9',
      reviews: '203',
      category: '美容・リラクゼーション',
      subcategory: 'ネイル',
      location: '東京都',
      address: '東京都港区青山1-2-3',
      date: '2025年10月20日（月）',
      time: '11:00 - 13:00',
      description: 'トレンドを押さえたおしゃれなデザインから、シンプルで上品なスタイルまで対応。高品質ジェルで美しい仕上がりが長持ちします。',
      providerId: 'test_provider_003',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'ジェルネイル（ワンカラー）', price: '¥5,500', duration: '90分', description: 'シンプルで上品な単色ネイル'),
        MenuItem(name: 'アートデザイン（2本）', price: '¥2,000', duration: '30分', description: 'お好みのデザインを2本に'),
      ],
      totalPrice: '¥7,500',
      reviewsList: [
        ServiceReview(
          userName: '西村 麻衣',
          rating: 5.0,
          comment: 'デザインのセンスが素晴らしく、毎回満足しています。持ちも良くて助かります！',
          date: '2025年10月14日',
        ),
        ServiceReview(
          userName: '藤田 理恵',
          rating: 5.0,
          comment: '丁寧な施術と提案力が素晴らしいです。爪の状態も良くなりました。',
          date: '2025年10月10日',
        ),
        ServiceReview(
          userName: '岡田 さやか',
          rating: 4.5,
          comment: 'いつも可愛いデザインにしていただいています。サロンより気軽で便利です。',
          date: '2025年10月06日',
        ),
        ServiceReview(
          userName: '清水 綾',
          rating: 5.0,
          comment: '細かいアートも丁寧に仕上げてくださり、大満足です。',
          date: '2025年10月02日',
        ),
      ],
    ),
    ServiceModel(
      id: '4',
      title: 'フットネイル',
      provider: '山田 奈々',
      providerTitle: 'ネイルサロンオーナー',
      price: '¥6,800',
      rating: '4.8',
      reviews: '156',
      category: '美容・リラクゼーション',
      subcategory: 'ネイル',
      location: '千葉県',
      address: '千葉県千葉市中央区新町1-1-1',
      date: '2025年10月21日（火）',
      time: '15:00 - 16:30',
      description: '足元を美しく彩るフットネイル。ケアからカラーリングまで丁寧に施術します。サンダルシーズンも自信を持って過ごせます。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'フットジェルネイル', price: '¥6,800', duration: '90分', description: 'ケア込みのフットネイル'),
      ],
      totalPrice: '¥6,800',
      reviewsList: [
        ServiceReview(
          userName: '佐々木 美緒',
          rating: 5.0,
          comment: 'フットケアがとても丁寧で、仕上がりも完璧でした。足がすっきりします！',
          date: '2025年10月13日',
        ),
        ServiceReview(
          userName: '橋本 愛子',
          rating: 4.5,
          comment: '自宅で受けられるのが便利です。デザインの提案も的確で満足しています。',
          date: '2025年10月09日',
        ),
        ServiceReview(
          userName: '長谷川 真由美',
          rating: 5.0,
          comment: '角質ケアも含めて丁寧に施術してくださいました。また利用します。',
          date: '2025年10月05日',
        ),
      ],
    ),

    // 美容・リラクゼーション - マッサージ
    ServiceModel(
      id: '5',
      title: 'もみほぐし＆タイ式マッサージ',
      provider: 'テスト 太郎',
      providerTitle: 'プロマッサージ師',
      price: '¥4,500〜',
      rating: '4.7',
      reviews: '156',
      category: '美容・リラクゼーション',
      subcategory: 'マッサージ',
      location: '東京都',
      address: '東京都世田谷区三軒茶屋1-2-3',
      date: '2025年10月17日（金）',
      time: '18:00 - 19:30',
      description: '疲れた体をほぐす本格的なマッサージをご自宅で。もみほぐしからタイ式まで、お好みのスタイルをお選びいただけます。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(
          name: 'もみほぐし 60分',
          price: '¥4,500',
          duration: '60分',
          description: '全身のコリをほぐすスタンダードコース',
        ),
        MenuItem(
          name: 'もみほぐし 90分',
          price: '¥6,500',
          duration: '90分',
          description: 'じっくり全身をほぐす人気コース',
        ),
        MenuItem(
          name: 'タイ式マッサージ 60分',
          price: '¥5,500',
          duration: '60分',
          description: 'ストレッチを組み合わせたタイ伝統式',
        ),
        MenuItem(
          name: 'タイ式マッサージ 90分',
          price: '¥8,000',
          duration: '90分',
          description: 'ゆったりとしたタイ式フルコース',
        ),
        MenuItem(
          name: 'ヘッドマッサージ 30分',
          price: '¥3,000',
          duration: '30分',
          description: '頭部のコリと眼精疲労に',
        ),
        MenuItem(
          name: 'フットマッサージ 45分',
          price: '¥4,000',
          duration: '45分',
          description: '足のむくみと疲れを解消',
        ),
      ],
      totalPrice: '¥4,500〜',
      reviewsList: [
        ServiceReview(
          userName: '山田 太郎',
          rating: 5.0,
          comment: '技術が素晴らしく、体が軽くなりました。自宅で受けられるのがとても便利です。',
          date: '2025年10月10日',
        ),
        ServiceReview(
          userName: '佐藤 花子',
          rating: 4.5,
          comment: 'もみほぐし90分を受けました。力加減も丁度良く、とてもリラックスできました。',
          date: '2025年10月08日',
        ),
        ServiceReview(
          userName: '鈴木 一郎',
          rating: 5.0,
          comment: 'タイ式マッサージが最高でした！また予約します。',
          date: '2025年10月05日',
        ),
        ServiceReview(
          userName: '田中 美咲',
          rating: 4.0,
          comment: '丁寧な施術でした。もう少し強めが好みですが、満足です。',
          date: '2025年10月03日',
        ),
      ],
    ),
    ServiceModel(
      id: '6',
      title: 'アロママッサージ＆リンパケア',
      provider: '高橋 麗子',
      providerTitle: 'アロマセラピスト',
      price: '¥6,000〜',
      rating: '4.9',
      reviews: '187',
      category: '美容・リラクゼーション',
      subcategory: 'マッサージ',
      location: '埼玉県',
      address: '埼玉県さいたま市浦和区高砂2-1-1',
      date: '2025年10月22日（水）',
      time: '16:00 - 18:00',
      description: '香り豊かなアロマオイルを使用した癒しのマッサージ。リンパの流れを改善し、美容効果も期待できます。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(
          name: 'アロママッサージ 60分',
          price: '¥6,000',
          duration: '60分',
          description: 'お好みの香りで全身リラックス',
        ),
        MenuItem(
          name: 'アロママッサージ 90分',
          price: '¥8,500',
          duration: '90分',
          description: 'たっぷり時間をかけた贅沢コース',
        ),
        MenuItem(
          name: 'アロママッサージ 120分',
          price: '¥10,500',
          duration: '120分',
          description: 'フルボディの至福のひととき',
        ),
        MenuItem(
          name: 'リンパドレナージュ 60分',
          price: '¥7,000',
          duration: '60分',
          description: 'むくみ解消に特化した施術',
        ),
        MenuItem(
          name: 'フェイシャルアロマ 45分',
          price: '¥5,500',
          duration: '45分',
          description: '顔のむくみとくすみケア',
        ),
      ],
      totalPrice: '¥6,000〜',
      reviewsList: [
        ServiceReview(
          userName: '中村 優子',
          rating: 5.0,
          comment: 'アロマの香りに癒されながら、とても丁寧な施術でした。むくみがすっきり取れました！',
          date: '2025年10月12日',
        ),
        ServiceReview(
          userName: '伊藤 真理',
          rating: 5.0,
          comment: 'リンパドレナージュを受けました。翌日の体の軽さに驚きました。',
          date: '2025年10月09日',
        ),
        ServiceReview(
          userName: '渡辺 健',
          rating: 4.5,
          comment: 'アロママッサージ90分、最高でした。また利用します。',
          date: '2025年10月06日',
        ),
        ServiceReview(
          userName: '小林 愛',
          rating: 5.0,
          comment: '高橋さんの技術とお人柄が素晴らしく、安心して任せられました。',
          date: '2025年10月01日',
        ),
      ],
    ),

    // 記念・ライフスタイル - ベビーフォト
    ServiceModel(
      id: '7',
      title: 'ベビーフォト',
      provider: '山田 花子',
      providerTitle: 'プロフォトグラファー',
      price: '¥11,000',
      rating: '4.9',
      reviews: '128',
      category: '記念・ライフスタイル',
      subcategory: 'ベビーフォト',
      location: '東京都',
      address: '東京都渋谷区恵比寿1-2-3',
      date: '2025年10月20日（月）',
      time: '14:00 - 16:00',
      description: '赤ちゃんの自然な表情を引き出す出張撮影。お気に入りの場所で、リラックスした雰囲気の中での撮影が可能です。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'ベビーフォト撮影（60分）', price: '¥8,000', duration: '60分', description: '自然な表情を引き出す撮影'),
        MenuItem(name: 'データ納品（30枚）', price: '¥3,000', description: '厳選した30枚をデータで'),
      ],
      totalPrice: '¥11,000',
      reviewsList: [
        ServiceReview(
          userName: '石川 明子',
          rating: 5.0,
          comment: '赤ちゃんのペースに合わせて撮影してくださり、素敵な写真がたくさん撮れました！',
          date: '2025年10月12日',
        ),
        ServiceReview(
          userName: '前田 さゆり',
          rating: 5.0,
          comment: '自宅での撮影で娘もリラックスしていて、自然な笑顔が撮れました。大満足です。',
          date: '2025年10月08日',
        ),
        ServiceReview(
          userName: '村上 恵',
          rating: 4.5,
          comment: 'プロの技術で素晴らしい写真になりました。良い記念になります。',
          date: '2025年10月04日',
        ),
        ServiceReview(
          userName: '吉田 真紀',
          rating: 5.0,
          comment: '赤ちゃんの扱いに慣れていて安心でした。データ納品も早くて助かりました。',
          date: '2025年10月01日',
        ),
      ],
    ),
    ServiceModel(
      id: '8',
      title: 'ニューボーンフォト',
      provider: '森田 直樹',
      providerTitle: 'ベビーフォト専門カメラマン',
      price: '¥15,000',
      rating: '4.9',
      reviews: '92',
      category: '記念・ライフスタイル',
      subcategory: 'ベビーフォト',
      location: '神奈川県',
      address: '神奈川県川崎市中原区小杉町1-1-1',
      date: '2025年10月23日（木）',
      time: '10:00 - 12:00',
      description: '生後2週間以内の新生児の貴重な瞬間を記録。安全を最優先に、赤ちゃんに優しい撮影を行います。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'ニューボーン撮影（90分）', price: '¥12,000', duration: '90分', description: '新生児の安全を最優先した撮影'),
        MenuItem(name: 'アルバム作成', price: '¥3,000', description: 'プレミアムアルバム作成'),
      ],
      totalPrice: '¥15,000',
      reviewsList: [
        ServiceReview(
          userName: '三浦 咲',
          rating: 5.0,
          comment: '生後10日での撮影でしたが、赤ちゃんの扱いがとても丁寧で安心できました。一生の宝物です。',
          date: '2025年10月11日',
        ),
        ServiceReview(
          userName: '岩田 千春',
          rating: 5.0,
          comment: '新生児の撮影に慣れていて、眠っている間に素敵な写真を撮っていただきました。',
          date: '2025年10月07日',
        ),
        ServiceReview(
          userName: '上田 美里',
          rating: 4.5,
          comment: '小さな手足のクローズアップなど、プロならではの構図が素晴らしかったです。',
          date: '2025年10月03日',
        ),
      ],
    ),

    // 記念・ライフスタイル - 出張カメラマン
    ServiceModel(
      id: '9',
      title: '出張カメラマン',
      provider: '佐々木 明',
      providerTitle: 'フォトグラファー',
      price: '¥10,000',
      rating: '4.9',
      reviews: '167',
      category: '記念・ライフスタイル',
      subcategory: '出張カメラマン（家族写真・プロフィール写真など）',
      location: '東京都',
      address: '東京都新宿区西新宿1-1-1',
      date: '2025年10月24日（金）',
      time: '13:00 - 15:00',
      description: '家族写真からプロフィール写真まで、ご希望の場所で撮影します。自然な表情を引き出すプロの技術で、思い出に残る写真を。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: '家族写真撮影（120分）', price: '¥10,000', duration: '120分', description: '家族の自然な笑顔を撮影'),
      ],
      totalPrice: '¥10,000',
      reviewsList: [
        ServiceReview(
          userName: '木下 健太',
          rating: 5.0,
          comment: '家族みんなが自然な笑顔で写っている写真が撮れました。公園での撮影が楽しかったです。',
          date: '2025年10月14日',
        ),
        ServiceReview(
          userName: '池田 美咲',
          rating: 5.0,
          comment: 'プロフィール写真を撮影していただきました。ライティングと構図が完璧でした！',
          date: '2025年10月10日',
        ),
        ServiceReview(
          userName: '山崎 雄一',
          rating: 4.5,
          comment: '子供たちの撮影に慣れていて、飽きさせずに楽しく撮影できました。',
          date: '2025年10月06日',
        ),
        ServiceReview(
          userName: '斉藤 彩花',
          rating: 5.0,
          comment: '七五三の記念撮影をお願いしました。素敵な写真が撮れて大満足です。',
          date: '2025年10月02日',
        ),
      ],
    ),

    // 子育て・家事サポート - 保育
    ServiceModel(
      id: '10',
      title: 'ベビーシッター',
      provider: '木村 優子',
      providerTitle: '保育士',
      price: '¥3,500',
      rating: '4.8',
      reviews: '234',
      category: '子育て・家事サポート',
      subcategory: '保育',
      location: '東京都',
      address: '東京都目黒区自由が丘1-1-1',
      date: '2025年10月25日（土）',
      time: '09:00 - 12:00',
      description: '保育士資格を持つプロのシッターがお子様を安全にお預かりします。急な用事や息抜きの時間に。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'ベビーシッター（3時間）', price: '¥3,500', duration: '3時間', description: '保育士による安心のシッティング'),
      ],
      totalPrice: '¥3,500',
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
          comment: '急な用事でお願いしましたが、丁寧に対応してくださいました。また利用します。',
          date: '2025年10月11日',
        ),
        ServiceReview(
          userName: '新井 恵理',
          rating: 5.0,
          comment: '子供の扱いに慣れていて、報告も細かくしてくださるので安心です。',
          date: '2025年10月07日',
        ),
        ServiceReview(
          userName: '平野 美奈',
          rating: 4.5,
          comment: '遊びも工夫してくれて、子供が大満足でした。とても助かります。',
          date: '2025年10月03日',
        ),
      ],
    ),
    ServiceModel(
      id: '11',
      title: '送迎シッター',
      provider: '伊藤 真理子',
      providerTitle: '認定ベビーシッター',
      price: '¥4,500',
      rating: '4.7',
      reviews: '178',
      category: '子育て・家事サポート',
      subcategory: '保育',
      location: '神奈川県',
      address: '神奈川県横浜市港北区日吉1-1-1',
      date: '2025年10月26日（日）',
      time: '15:00 - 18:00',
      description: '習い事や保育園への送り迎えとシッティングをセットで提供。お仕事で忙しい時も安心です。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: '保育＋送迎（3時間）', price: '¥4,500', duration: '3時間', description: '送迎とシッティングのセット'),
      ],
      totalPrice: '¥4,500',
      reviewsList: [
        ServiceReview(
          userName: '福田 さおり',
          rating: 5.0,
          comment: '習い事の送迎をお願いしました。時間通りで安心してお任せできます。',
          date: '2025年10月13日',
        ),
        ServiceReview(
          userName: '本田 麻美',
          rating: 4.5,
          comment: '保育園のお迎えから夕食まで見ていただき、とても助かりました。',
          date: '2025年10月09日',
        ),
        ServiceReview(
          userName: '宮崎 百合子',
          rating: 4.5,
          comment: '子供も慣れてきて、楽しく通っています。信頼できるシッターさんです。',
          date: '2025年10月05日',
        ),
      ],
    ),

    // 子育て・家事サポート - 家事
    ServiceModel(
      id: '12',
      title: '家事代行サービス',
      provider: '小林 真理',
      providerTitle: '家事代行スタッフ',
      price: '¥4,000',
      rating: '4.7',
      reviews: '176',
      category: '子育て・家事サポート',
      subcategory: '家事',
      location: '東京都',
      address: '東京都品川区大井1-1-1',
      date: '2025年10月27日（月）',
      time: '10:00 - 12:00',
      description: '掃除、洗濯、片付けなどの日常家事をプロがお手伝い。忙しい毎日に余裕を作ります。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: '掃除・洗濯（2時間）', price: '¥4,000', duration: '2時間', description: '日常的な家事全般をサポート'),
      ],
      totalPrice: '¥4,000',
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
        ServiceReview(
          userName: '森本 麻里',
          rating: 4.5,
          comment: '効率的に作業してくださり、短時間で家がすっきりしました。',
          date: '2025年10月06日',
        ),
        ServiceReview(
          userName: '川口 香織',
          rating: 4.0,
          comment: '定期的にお願いしています。いつも丁寧に対応してくださいます。',
          date: '2025年10月02日',
        ),
      ],
    ),

    // 子育て・家事サポート - 出張料理
    ServiceModel(
      id: '13',
      title: '出張料理シェフ',
      provider: '山本 健二',
      providerTitle: 'プロシェフ',
      price: '¥12,000',
      rating: '4.8',
      reviews: '156',
      category: '子育て・家事サポート',
      subcategory: '出張料理・作り置きシェフ',
      location: '東京都',
      address: '東京都中央区銀座4-1-1',
      date: '2025年10月28日（火）',
      time: '17:00 - 20:00',
      description: 'プロのシェフがご自宅で作り置き料理を調理。栄養バランスの取れた美味しい料理で毎日の食事を楽にします。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: '作り置き料理（5品）', price: '¥10,000', duration: '3時間', description: 'プロの味を毎日の食卓に'),
        MenuItem(name: '材料費', price: '¥2,000', description: '食材費込み'),
      ],
      totalPrice: '¥12,000',
      reviewsList: [
        ServiceReview(
          userName: '竹内 洋子',
          rating: 5.0,
          comment: 'プロの味で栄養バランスも完璧！平日の食事がとても楽になりました。',
          date: '2025年10月12日',
        ),
        ServiceReview(
          userName: '松井 恵美',
          rating: 5.0,
          comment: '子供たちもパクパク食べてくれます。レシピも教えていただけて勉強になります。',
          date: '2025年10月08日',
        ),
        ServiceReview(
          userName: '山口 孝之',
          rating: 4.5,
          comment: '仕事で忙しい時に大変助かっています。美味しくて栄養満点です。',
          date: '2025年10月04日',
        ),
        ServiceReview(
          userName: '金子 理沙',
          rating: 4.5,
          comment: '品数も豊富で、飽きずに食べられます。また来月もお願いします。',
          date: '2025年10月01日',
        ),
      ],
    ),

    // 健康・学び - ヨガ
    ServiceModel(
      id: '14',
      title: 'ヨガインストラクター',
      provider: '井上 美穂',
      providerTitle: 'ヨガインストラクター',
      price: '¥7,000',
      rating: '4.8',
      reviews: '143',
      category: '健康・学び',
      subcategory: 'フィットネス／ヨガ／ピラティスのインストラクター派遣',
      location: '東京都',
      address: '東京都杉並区荻窪1-1-1',
      date: '2025年10月29日（水）',
      time: '07:00 - 08:00',
      description: '自宅でマンツーマンのヨガレッスン。初心者から経験者まで、一人ひとりのレベルに合わせた指導を行います。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'プライベートヨガレッスン（60分）', price: '¥7,000', duration: '60分', description: 'パーソナルな指導で効果的に'),
      ],
      totalPrice: '¥7,000',
      reviewsList: [
        ServiceReview(
          userName: '須藤 奈緒',
          rating: 5.0,
          comment: '初心者でしたが、丁寧に教えてくださり、続けられそうです。体が軽くなりました！',
          date: '2025年10月15日',
        ),
        ServiceReview(
          userName: '原田 瑠美',
          rating: 4.5,
          comment: '自宅でのレッスンなので、気軽に受けられます。姿勢が良くなってきました。',
          date: '2025年10月11日',
        ),
        ServiceReview(
          userName: '小川 絵美',
          rating: 5.0,
          comment: 'レベルに合わせて調整してくださるので、無理なく続けられます。',
          date: '2025年10月07日',
        ),
        ServiceReview(
          userName: '阿部 恵理子',
          rating: 4.5,
          comment: '朝ヨガで1日をスタートするのが習慣になりました。心身ともにリフレッシュできます。',
          date: '2025年10月03日',
        ),
      ],
    ),

    // 健康・学び - 英会話
    ServiceModel(
      id: '15',
      title: '英会話レッスン',
      provider: 'Smith John',
      providerTitle: '英会話講師',
      price: '¥5,500',
      rating: '4.9',
      reviews: '201',
      category: '健康・学び',
      subcategory: '語学・音楽・習い事レッスン（ピアノ・英会話など）',
      location: '東京都',
      address: '東京都文京区本郷1-1-1',
      date: '2025年10月30日（木）',
      time: '19:00 - 20:00',
      description: 'ネイティブ講師によるプライベート英会話レッスン。日常会話からビジネス英語まで、目的に合わせた指導を行います。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'プライベート英会話レッスン（60分）', price: '¥5,500', duration: '60分', description: 'ネイティブによる実践的なレッスン'),
      ],
      totalPrice: '¥5,500',
      reviewsList: [
        ServiceReview(
          userName: '西川 大輔',
          rating: 5.0,
          comment: 'とてもフレンドリーな先生で、楽しくレッスンを受けられます。英語力が確実に上がっています。',
          date: '2025年10月13日',
        ),
        ServiceReview(
          userName: '田辺 智子',
          rating: 5.0,
          comment: 'ビジネス英語を学んでいます。実践的な内容で、すぐに仕事で使えます。',
          date: '2025年10月09日',
        ),
        ServiceReview(
          userName: '藤井 健司',
          rating: 4.5,
          comment: '発音をしっかり直してくれるので、リスニング力も上がりました。',
          date: '2025年10月05日',
        ),
        ServiceReview(
          userName: '谷口 沙織',
          rating: 5.0,
          comment: '子供にも教えていただいています。楽しみながら学べて素晴らしいです。',
          date: '2025年10月01日',
        ),
      ],
    ),

    // ペット・生活環境 - ペットケア
    ServiceModel(
      id: '16',
      title: 'ペットシッター',
      provider: '大野 愛',
      providerTitle: '動物看護師',
      price: '¥3,000',
      rating: '4.7',
      reviews: '189',
      category: 'ペット・生活環境',
      subcategory: 'ペットケア・散歩代行',
      location: '東京都',
      address: '東京都練馬区石神井町1-1-1',
      date: '2025年10月31日（金）',
      time: '12:00 - 13:00',
      description: '動物看護師によるペットのお世話と散歩代行。大切な家族を安心してお任せいただけます。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'ペットケア・散歩（60分）', price: '¥3,000', duration: '60分', description: '愛犬の健康的なお散歩'),
      ],
      totalPrice: '¥3,000',
      reviewsList: [
        ServiceReview(
          userName: '久保田 薫',
          rating: 5.0,
          comment: '動物看護師さんなので安心してお願いできます。愛犬もとても懐いています。',
          date: '2025年10月14日',
        ),
        ServiceReview(
          userName: '荒木 直子',
          rating: 4.5,
          comment: '仕事で忙しい日に助かっています。散歩の様子を写真で送ってくださるのも嬉しいです。',
          date: '2025年10月10日',
        ),
        ServiceReview(
          userName: '近藤 博之',
          rating: 4.5,
          comment: '丁寧にお世話してくださり、帰宅すると犬が満足そうです。',
          date: '2025年10月06日',
        ),
        ServiceReview(
          userName: '関 美由紀',
          rating: 5.0,
          comment: '高齢犬のケアもお願いしています。知識が豊富で信頼できます。',
          date: '2025年10月02日',
        ),
      ],
    ),

    // ペット・生活環境 - ハウスクリーニング
    ServiceModel(
      id: '17',
      title: 'ハウスクリーニング',
      provider: '田村 誠一',
      providerTitle: 'クリーニングスペシャリスト',
      price: '¥9,000',
      rating: '4.8',
      reviews: '132',
      category: 'ペット・生活環境',
      subcategory: '出張ハウスクリーニング（エアコン・水回り専門）',
      location: '東京都',
      address: '東京都江戸川区西葛西1-1-1',
      date: '2025年11月01日（土）',
      time: '10:00 - 12:00',
      description: 'エアコンや水回りなど、専門的な清掃が必要な箇所をプロが徹底洗浄。清潔で快適な住環境を実現します。',
      providerId: 'test_provider_001',
      salonId: 'test_salon_001',
      menuItems: [
        MenuItem(name: 'エアコンクリーニング（2台）', price: '¥9,000', duration: '2時間', description: '内部まで徹底洗浄'),
      ],
      totalPrice: '¥9,000',
      reviewsList: [
        ServiceReview(
          userName: '田口 幸子',
          rating: 5.0,
          comment: 'エアコンが新品のようになりました！風が全然違います。プロの技術に感動です。',
          date: '2025年10月12日',
        ),
        ServiceReview(
          userName: '浜田 剛',
          rating: 4.5,
          comment: '水回りもお願いしました。頑固な汚れがピカピカになりました。',
          date: '2025年10月08日',
        ),
        ServiceReview(
          userName: '黒田 祐介',
          rating: 5.0,
          comment: '作業が丁寧で、仕上がりが完璧でした。また次回もお願いします。',
          date: '2025年10月04日',
        ),
        ServiceReview(
          userName: '横山 京子',
          rating: 4.5,
          comment: '掃除後の説明も丁寧で、メンテナンスのアドバイスもいただけました。',
          date: '2025年10月01日',
        ),
      ],
    ),
  ];

  // Get all services
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
