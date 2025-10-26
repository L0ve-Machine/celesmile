import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/database_service.dart';
import '../services/profile_image_service.dart';
import '../services/mysql_service.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late Map<String, dynamic> searchFilters;
  Future<List<Map<String, dynamic>>>? _servicesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get search filters passed from dashboard
    searchFilters = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _loadServices();
  }

  void _loadServices() {
    _servicesFuture = MySQLService.instance.getServices(
      category: searchFilters['category'],
      subcategory: searchFilters['subcategory'],
      location: searchFilters['location'],
      search: searchFilters['searchQuery'],
    );
  }

  bool _matchesDate(String serviceDate, DateTime selectedDate) {
    final yearMatch = RegExp(r'(\d{4})年').firstMatch(serviceDate);
    final monthMatch = RegExp(r'(\d{1,2})月').firstMatch(serviceDate);
    final dayMatch = RegExp(r'(\d{1,2})日').firstMatch(serviceDate);

    if (yearMatch == null || monthMatch == null || dayMatch == null) {
      return false;
    }

    final year = int.parse(yearMatch.group(1)!);
    final month = int.parse(monthMatch.group(1)!);
    final day = int.parse(dayMatch.group(1)!);

    return year == selectedDate.year &&
        month == selectedDate.month &&
        day == selectedDate.day;
  }

  bool _matchesTimeRange(String serviceTime, String timeRange) {
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(serviceTime);
    if (timeMatch == null) return false;

    final startHour = int.parse(timeMatch.group(1)!);

    switch (timeRange) {
      case 'morning':
        return startHour >= 6 && startHour < 12;
      case 'afternoon':
        return startHour >= 12 && startHour < 18;
      case 'evening':
        return startHour >= 18 && startHour < 24;
      case 'latenight':
        return startHour >= 0 && startHour < 6;
      default:
        return true;
    }
  }

  String _getPageTitle() {
    if (searchFilters['searchQuery'] != null && searchFilters['searchQuery'].isNotEmpty) {
      return '"${searchFilters['searchQuery']}" の検索結果';
    } else if (searchFilters['subcategory'] != null) {
      return '${searchFilters['subcategory']}';
    } else if (searchFilters['category'] != null) {
      return '${searchFilters['category']}';
    }
    return '検索結果';
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
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final servicesData = snapshot.data!;

          // Convert to ServiceModel for compatibility
          final db = DatabaseService();
          final allServices = db.filterServices();
          final filteredServices = servicesData.map((data) {
            return allServices.firstWhere(
              (s) => s.id == data['id'],
              orElse: () => allServices.first,
            );
          }).toList();

          return filteredServices.isEmpty
              ? _buildEmptyState()
              : _buildServiceList(filteredServices);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            '該当するサービスが見つかりませんでした',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '条件を変更して再度お試しください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList(List<ServiceModel> filteredServices) {
    return Column(
      children: [
        // Results count header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '検索結果',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredServices.length}件',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Service list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredServices.length,
            itemBuilder: (context, index) {
              return _buildServiceCard(filteredServices[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/service-detail',
          arguments: service.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Provider profile image
            ProfileImageService().buildProfileImage(
              userId: service.providerId ?? 'test_provider_001',
              isProvider: true,
              size: 80,
              defaultIcon: Icons.person,
            ),
            const SizedBox(width: 12),
            // Service details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.provider,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      service.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.rating} (${service.reviews})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        service.price,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
