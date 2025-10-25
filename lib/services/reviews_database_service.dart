import '../services/database_service.dart';

class ReviewsDatabaseService {
  static final ReviewsDatabaseService _instance = ReviewsDatabaseService._internal();
  factory ReviewsDatabaseService() => _instance;
  ReviewsDatabaseService._internal();

  // Local storage for reviews
  final Map<String, List<ServiceReview>> _reviewsStorage = {};

  // Initialize with default reviews from services
  void initializeReviews() {
    final db = DatabaseService();
    final services = db.getAllServices();

    for (var service in services) {
      _reviewsStorage[service.id] = List.from(service.reviewsList);
    }
  }

  // Get reviews for a specific service
  List<ServiceReview> getReviewsForService(String serviceId) {
    if (_reviewsStorage.isEmpty) {
      initializeReviews();
    }
    return _reviewsStorage[serviceId] ?? [];
  }

  // Add a new review
  void addReview(String serviceId, ServiceReview review) {
    if (_reviewsStorage.isEmpty) {
      initializeReviews();
    }

    if (_reviewsStorage.containsKey(serviceId)) {
      _reviewsStorage[serviceId]!.insert(0, review);
    } else {
      _reviewsStorage[serviceId] = [review];
    }
  }

  // Get average rating for a service
  double getAverageRating(String serviceId) {
    final reviews = getReviewsForService(serviceId);
    if (reviews.isEmpty) return 0.0;

    double sum = 0;
    for (var review in reviews) {
      sum += review.rating;
    }
    return sum / reviews.length;
  }

  // Get review count for a service
  int getReviewCount(String serviceId) {
    return getReviewsForService(serviceId).length;
  }

  // Delete a review (by index)
  void deleteReview(String serviceId, int index) {
    if (_reviewsStorage.containsKey(serviceId)) {
      if (index >= 0 && index < _reviewsStorage[serviceId]!.length) {
        _reviewsStorage[serviceId]!.removeAt(index);
      }
    }
  }

  // Edit a review
  void editReview(String serviceId, int index, ServiceReview updatedReview) {
    if (_reviewsStorage.containsKey(serviceId)) {
      if (index >= 0 && index < _reviewsStorage[serviceId]!.length) {
        _reviewsStorage[serviceId]![index] = updatedReview;
      }
    }
  }

  // Get all reviews across all services (for admin purposes)
  Map<String, List<ServiceReview>> getAllReviews() {
    if (_reviewsStorage.isEmpty) {
      initializeReviews();
    }
    return Map.from(_reviewsStorage);
  }

  // Clear all reviews for a service
  void clearReviewsForService(String serviceId) {
    if (_reviewsStorage.containsKey(serviceId)) {
      _reviewsStorage[serviceId]!.clear();
    }
  }

  // Filter reviews by rating
  List<ServiceReview> getReviewsByRating(String serviceId, double minRating) {
    final reviews = getReviewsForService(serviceId);
    return reviews.where((review) => review.rating >= minRating).toList();
  }

  // Get recent reviews (last N reviews)
  List<ServiceReview> getRecentReviews(String serviceId, int count) {
    final reviews = getReviewsForService(serviceId);
    return reviews.take(count).toList();
  }

  // Get rating distribution (how many 5-star, 4-star, etc.)
  Map<int, int> getRatingDistribution(String serviceId) {
    final reviews = getReviewsForService(serviceId);
    final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0, 0: 0};

    for (var review in reviews) {
      final starRating = review.rating.round();
      distribution[starRating] = (distribution[starRating] ?? 0) + 1;
    }

    return distribution;
  }
}
