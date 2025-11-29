import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/phone_verification_screen.dart';
import 'screens/account_setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_registration_screen.dart';
import 'screens/payment_registration_screen.dart';
import 'screens/user_settings_screen.dart';
import 'screens/poster_registration_intro_screen.dart';
import 'screens/poster_registration_form_screen.dart';
import 'screens/booking_confirmation_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/service_detail_screen.dart';
import 'screens/provider_home_dashboard_screen.dart';
import 'screens/provider_profile_form_screen.dart';
import 'screens/salon_info_form_screen.dart';
import 'screens/listing_information_screen.dart';
import 'screens/menu_registration_screen.dart';
import 'screens/identity_verification_screen.dart';
import 'screens/bank_registration_screen.dart';
import 'screens/provider_verification_status_screen.dart';
import 'screens/provider_verification_waiting_screen.dart';
import 'screens/provider_availability_calendar_screen.dart';
import 'screens/provider_bookings_screen.dart';
import 'screens/provider_income_summary_screen.dart';
import 'screens/provider_my_salons_screen.dart';
import 'screens/provider_settings_screen.dart';
import 'screens/provider_profile_edit_screen.dart';
import 'screens/provider_password_change_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_room_screen.dart';
import 'screens/debug_chat_screen.dart';
import 'screens/provider_chat_list_screen.dart';
import 'screens/search_results_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/terms_of_service_screen.dart';
import 'constants/colors.dart';
import 'services/provider_database_service.dart';
import 'services/notification_service.dart';
import 'config/stripe_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Stripe only on mobile platforms
  // Web has limited support and requires different setup
  if (!kIsWeb) {
    try {
      Stripe.publishableKey = StripeConfig.publishableKey;
      Stripe.merchantIdentifier = 'merchant.com.celesmile';
    } catch (e) {
      print('Stripe initialization error: $e');
    }
  }

  // Initialize provider database to publish test services
  ProviderDatabaseService();

  // Initialize notification service for booking reminders
  NotificationService().initialize();

  // Request notification permission on first launch (mobile only)
  if (!kIsWeb) {
    await NotificationService.requestNotificationPermission();
  }

  runApp(const CelesmileApp());
}

class CelesmileApp extends StatelessWidget {
  const CelesmileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Celesmile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.orange,
        scaffoldBackgroundColor: AppColors.lightBeige,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
          primary: AppColors.orange,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/phone-verification': (context) => const PhoneVerificationScreen(),
        '/account-setup': (context) => const AccountSetupScreen(),
        '/profile-registration': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ProfileRegistrationScreen(isEditMode: args?['isEditMode'] ?? false);
        },
        '/payment-registration': (context) => const PaymentRegistrationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/user-settings': (context) => const UserSettingsScreen(),
        '/terms-of-service': (context) => const TermsOfServiceScreen(),
        '/poster-registration-intro': (context) =>
            const PosterRegistrationIntroScreen(),
        '/poster-registration-form': (context) =>
            const PosterRegistrationFormScreen(),
        '/provider-home-dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return ProviderHomeDashboardScreen(providerId: args);
        },
        '/provider-verification-waiting': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          return ProviderVerificationWaitingScreen(
            providerId: args?['providerId'] ?? '',
            sessionId: args?['sessionId'] ?? '',
          );
        },
        '/provider-profile-form': (context) =>
            const ProviderProfileFormScreen(),
        '/salon-info-form': (context) => const SalonInfoFormScreen(),
        '/salon-registration': (context) => const SalonInfoFormScreen(),
        '/listing-information': (context) => const ListingInformationScreen(),
        '/menu-registration': (context) => const MenuRegistrationScreen(),
        '/identity-verification': (context) => const IdentityVerificationScreen(),
        '/bank-registration': (context) => const BankRegistrationScreen(),
        '/provider-verification-status': (context) =>
            const ProviderVerificationStatusScreen(),
        '/provider-availability-calendar': (context) =>
            const ProviderAvailabilityCalendarScreen(),
        '/provider-bookings': (context) => const ProviderBookingsScreen(),
        '/provider-income-summary': (context) =>
            const ProviderIncomeSummaryScreen(),
        '/provider-my-salons': (context) => const ProviderMySalonsScreen(),
        '/provider-settings': (context) => const ProviderSettingsScreen(),
        '/provider-profile-edit': (context) => const ProviderProfileEditScreen(),
        '/provider-password-change': (context) => const ProviderPasswordChangeScreen(),
        '/service-detail': (context) => const ServiceDetailScreen(),
        '/booking-confirmation': (context) =>
            const BookingConfirmationScreen(),
        '/booking-history': (context) => const BookingHistoryScreen(),
        '/chat-list': (context) => const ChatListScreen(),
        '/chat-room': (context) => const ChatRoomScreen(),
        '/debug-chat': (context) => const DebugChatScreen(),
        '/provider-chat-list': (context) => const ProviderChatListScreen(),
        '/search-results': (context) => const SearchResultsScreen(),
        '/notification-settings': (context) => const NotificationSettingsScreen(),
      },
    );
  }
}
