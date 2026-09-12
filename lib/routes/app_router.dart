import 'package:go_router/go_router.dart';

import '../features/ai_brand_builder/models/generated_brand_model.dart';
import '../features/ai_brand_builder/screens/ai_brand_builder_screen.dart';
import '../features/ai_brand_builder/screens/ai_brand_studio_screen.dart';
import '../features/ai_brand_builder/screens/ai_logo_generation_screen.dart';
import '../features/ai_brand_builder/screens/brand_generation_result_screen.dart';
import '../features/auth/screens/auth_gate.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/brand/screens/brand_profile_screen.dart';
import '../features/brand/screens/edit_brand_screen.dart';
import '../features/brand/screens/seller_brand_screen.dart';
import '../features/buyer/screens/buyer_home_screen.dart';
import '../features/buyer/screens/buyer_marketplace_screen.dart';
import '../features/buyer/screens/listing_details_screen.dart';
import '../features/buyer/screens/seller_storefront_screen.dart';
import '../features/chat/screens/conversations_screen.dart';
import '../features/listings/models/generated_listing_model.dart';
import '../features/listings/screens/ai_listing_builder_screen.dart';
import '../features/listings/screens/ai_listing_result_screen.dart';
import '../features/listings/screens/create_listing_screen.dart';
import '../features/listings/screens/edit_listing_screen.dart';
import '../features/listings/screens/my_listings_screen.dart';
import '../features/onboarding/screens/account_type_screen.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/orders/screens/buyer_orders_screen.dart';
import '../features/orders/screens/place_order_screen.dart';
import '../features/orders/screens/seller_order_details_screen.dart';
import '../features/orders/screens/seller_orders_screen.dart';
import '../features/reviews/screens/review_order_screen.dart';
import '../features/seller/screens/seller_analytics_screen.dart';
import '../features/seller/screens/seller_dashboard_screen.dart';
import '../features/seller/screens/seller_onboarding_screen.dart';
import '../features/settings/screens/account_settings_screen.dart';
import '../models/listing_model.dart';
import '../models/order_model.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AuthGate()),
      GoRoute(
        path: '/settings',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'buyer';
          return AccountSettingsScreen(role: role);
        },
      ),
      GoRoute(
        path: '/listing-details',
        builder: (context, state) => ListingDetailsScreen(listing: state.extra as ListingModel),
      ),
      GoRoute(
        path: '/seller-storefront',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return SellerStorefrontScreen(
            sellerId: (data['sellerId'] ?? '').toString(),
            brandId: (data['brandId'] ?? '').toString(),
          );
        },
      ),
      GoRoute(
        path: '/place-order',
        builder: (context, state) => PlaceOrderScreen(listing: state.extra as ListingModel),
      ),
      GoRoute(
        path: '/review-order',
        builder: (context, state) => ReviewOrderScreen(order: state.extra as OrderModel),
      ),
      GoRoute(
        path: '/seller-order-details',
        builder: (context, state) => SellerOrderDetailsScreen(order: state.extra as OrderModel),
      ),
      GoRoute(path: '/seller-analytics', builder: (context, state) => const SellerAnalyticsScreen()),
      GoRoute(path: '/ai-listing-builder', builder: (context, state) => const AIListingBuilderScreen()),
      GoRoute(
        path: '/ai-listing-result',
        builder: (context, state) => AIListingResultScreen(listing: state.extra as GeneratedListingModel),
      ),
      GoRoute(
        path: '/edit-listing',
        builder: (context, state) => EditListingScreen(listing: state.extra as ListingModel),
      ),
      GoRoute(path: '/marketplace', builder: (context, state) => const BuyerMarketplaceScreen()),
      GoRoute(
        path: '/edit-brand',
        builder: (context, state) => EditBrandScreen(brand: state.extra as Map<String, dynamic>),
      ),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/account-type', builder: (context, state) => const AccountTypeScreen()),
      GoRoute(path: '/seller-dashboard', builder: (context, state) => const SellerDashboardScreen()),
      GoRoute(path: '/seller-brand', builder: (context, state) => const SellerBrandScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'buyer';
          return RegisterScreen(role: role);
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(path: '/buyer-home', builder: (context, state) => const BuyerHomeScreen()),
      GoRoute(path: '/seller-onboarding', builder: (context, state) => const SellerOnboardingScreen()),
      GoRoute(
        path: '/create-listing',
        builder: (context, state) => CreateListingScreen(generatedListing: state.extra as GeneratedListingModel?),
      ),
      GoRoute(path: '/my-listings', builder: (context, state) => const MyListingsScreen()),
      GoRoute(path: '/buyer-orders', builder: (context, state) => const BuyerOrdersScreen()),
      GoRoute(path: '/seller-orders', builder: (context, state) => const SellerOrdersScreen()),
      GoRoute(path: '/messages', builder: (context, state) => const ConversationsScreen()),
      GoRoute(path: '/brand-profile', builder: (context, state) => const BrandProfileScreen()),
      GoRoute(path: '/ai-brand-builder', builder: (context, state) => const AIBrandBuilderScreen()),
      GoRoute(
        path: '/brand-generation-result',
        builder: (context, state) => BrandGenerationResultScreen(brand: state.extra as GeneratedBrandModel),
      ),
      GoRoute(
        path: '/ai-logo-generation',
        builder: (context, state) => AILogoGenerationScreen(brand: state.extra as GeneratedBrandModel),
      ),
      GoRoute(
        path: '/ai-brand-studio',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is GeneratedBrandModel) {
            return AIBrandStudioScreen(brand: extra);
          }
          final data = extra as Map<String, dynamic>;
          return AIBrandStudioScreen(
            brand: data['brand'] as GeneratedBrandModel,
            logoPreference: (data['logoPreference'] ?? 'ai').toString(),
            logoPath: data['logoPath']?.toString(),
          );
        },
      ),
    ],
  );
}
