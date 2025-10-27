import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import 'mysql_service.dart';

/// Service for managing profile images across the app
class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  // Cache for loaded images to avoid repeated file reads
  final Map<String, File?> _imageCache = {};

  // Cache for provider image URLs from MySQL
  final Map<String, String?> _providerImageUrlCache = {};

  /// Get profile image path from SharedPreferences
  Future<String?> getProfileImagePath(String userId, {bool isProvider = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isProvider ? 'provider_profile_image_$userId' : 'user_profile_image_$userId';
    return prefs.getString(key);
  }

  /// Save profile image path to SharedPreferences
  Future<void> saveProfileImagePath(String userId, String imagePath, {bool isProvider = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isProvider ? 'provider_profile_image_$userId' : 'user_profile_image_$userId';
    await prefs.setString(key, imagePath);

    // Update cache
    _imageCache[key] = File(imagePath);
  }

  /// Remove profile image
  Future<void> removeProfileImage(String userId, {bool isProvider = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isProvider ? 'provider_profile_image_$userId' : 'user_profile_image_$userId';
    await prefs.remove(key);

    // Clear cache
    _imageCache.remove(key);
  }

  /// Get profile image file (cached)
  Future<File?> getProfileImage(String userId, {bool isProvider = false}) async {
    final key = isProvider ? 'provider_profile_image_$userId' : 'user_profile_image_$userId';

    // Check cache first
    if (_imageCache.containsKey(key)) {
      return _imageCache[key];
    }

    // Load from SharedPreferences
    final imagePath = await getProfileImagePath(userId, isProvider: isProvider);
    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) {
        _imageCache[key] = file;
        return file;
      }
    }

    _imageCache[key] = null;
    return null;
  }

  /// Clear all cached images
  void clearCache() {
    _imageCache.clear();
    _providerImageUrlCache.clear();
  }

  /// Get provider profile image URL from MySQL
  Future<String?> getProviderImageUrl(String providerId) async {
    // Check cache first
    if (_providerImageUrlCache.containsKey(providerId)) {
      return _providerImageUrlCache[providerId];
    }

    try {
      final provider = await MySQLService.instance.getProviderById(providerId);
      final imageUrl = provider?['profile_image'] as String?;
      _providerImageUrlCache[providerId] = imageUrl;
      return imageUrl;
    } catch (e) {
      print('Error loading provider image URL: $e');
      _providerImageUrlCache[providerId] = null;
      return null;
    }
  }

  /// Build a profile avatar widget with the profile image
  Widget buildProfileAvatar({
    required String userId,
    bool isProvider = false,
    double radius = 20,
    IconData defaultIcon = Icons.person,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    // For providers, use network image from MySQL
    if (isProvider) {
      return FutureBuilder<String?>(
        future: getProviderImageUrl(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor ?? AppColors.secondaryOrange.withOpacity(0.3),
              child: SizedBox(
                width: radius * 0.6,
                height: radius * 0.6,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    iconColor ?? AppColors.primaryOrange,
                  ),
                ),
              ),
            );
          }

          final imageUrl = snapshot.data;

          if (imageUrl != null && imageUrl.isNotEmpty) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor ?? AppColors.secondaryOrange.withOpacity(0.3),
              backgroundImage: NetworkImage(imageUrl),
            );
          }

          return CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? AppColors.secondaryOrange.withOpacity(0.3),
            child: Icon(
              defaultIcon,
              color: iconColor ?? AppColors.primaryOrange,
              size: radius * 0.8,
            ),
          );
        },
      );
    }

    // For regular users, use local file
    return FutureBuilder<File?>(
      future: getProfileImage(userId, isProvider: isProvider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? AppColors.secondaryOrange.withOpacity(0.3),
            child: SizedBox(
              width: radius * 0.6,
              height: radius * 0.6,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  iconColor ?? AppColors.primaryOrange,
                ),
              ),
            ),
          );
        }

        final imageFile = snapshot.data;

        if (imageFile != null && imageFile.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? AppColors.secondaryOrange.withOpacity(0.3),
            backgroundImage: FileImage(imageFile),
          );
        }

        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? AppColors.secondaryOrange.withOpacity(0.3),
          child: Icon(
            defaultIcon,
            color: iconColor ?? AppColors.primaryOrange,
            size: radius * 0.8,
          ),
        );
      },
    );
  }

  /// Build a square profile image widget
  Widget buildProfileImage({
    required String userId,
    bool isProvider = false,
    double size = 80,
    IconData defaultIcon = Icons.person,
    Color? backgroundColor,
    Color? iconColor,
    BorderRadius? borderRadius,
  }) {
    // For providers, use network image from MySQL
    if (isProvider) {
      return FutureBuilder<String?>(
        future: getProviderImageUrl(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.secondaryOrange.withOpacity(0.3),
                borderRadius: borderRadius ?? BorderRadius.circular(8),
              ),
              child: Center(
                child: SizedBox(
                  width: size * 0.3,
                  height: size * 0.3,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      iconColor ?? AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
            );
          }

          final imageUrl = snapshot.data;

          if (imageUrl != null && imageUrl.isNotEmpty) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: borderRadius ?? BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            );
          }

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.secondaryOrange.withOpacity(0.3),
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
            child: Icon(
              defaultIcon,
              color: iconColor ?? AppColors.primaryOrange,
              size: size * 0.5,
            ),
          );
        },
      );
    }

    // For regular users, use local file
    return FutureBuilder<File?>(
      future: getProfileImage(userId, isProvider: isProvider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.secondaryOrange.withOpacity(0.3),
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
            child: Center(
              child: SizedBox(
                width: size * 0.3,
                height: size * 0.3,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    iconColor ?? AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
          );
        }

        final imageFile = snapshot.data;

        if (imageFile != null && imageFile.existsSync()) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(imageFile),
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.secondaryOrange.withOpacity(0.3),
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          child: Icon(
            defaultIcon,
            color: iconColor ?? AppColors.primaryOrange,
            size: size * 0.5,
          ),
        );
      },
    );
  }

  /// Get image provider for use in other widgets
  Future<ImageProvider?> getImageProvider(String userId, {bool isProvider = false}) async {
    final imageFile = await getProfileImage(userId, isProvider: isProvider);
    if (imageFile != null && await imageFile.exists()) {
      return FileImage(imageFile);
    }
    return null;
  }
}
