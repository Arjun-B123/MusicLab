import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Runtime configuration, supplied via --dart-define at build/run time so
/// real keys never get hardcoded or committed to the repo.
///
/// Example:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=xxxx \
///     --dart-define=REVENUECAT_API_KEY=xxxx
class AppConfig {
  // Defaults below are the project's client-facing keys (Supabase's
  // publishable key and RevenueCat's public SDK key) — both are designed to
  // ship inside a client app; access control lives server-side (Supabase
  // Row Level Security, RevenueCat entitlements), not in keeping these
  // secret. Override via --dart-define for a different environment.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tyzsqirlkbcvbdtrskyg.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable__3Rll8Ip1L4ct8l5t5axXg_mvP77b6r',
  );
  static const revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'test_bSjFaWwATNQnMgPmUqQTMIRzGKN',
  );

  /// Identifier of the entitlement configured in the RevenueCat dashboard
  /// that unlocks MusicLab Pro. Must match exactly what's set up there —
  /// currently "MusicLab Pro" (with the space/capitals) as created in the
  /// dashboard, not a slug like "pro".
  static const proEntitlementId = 'MusicLab Pro';

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// The RevenueCat SDK only supports iOS, Android, macOS, and web — not
  /// Windows/Linux desktop. Windows is only used here for local preview
  /// convenience (the real targets are iOS/Android), so RevenueCat calls
  /// must be skipped there rather than crash with a MissingPluginException.
  static bool get isRevenueCatSupportedPlatform =>
      kIsWeb || Platform.isIOS || Platform.isAndroid || Platform.isMacOS;

  static bool get hasRevenueCatConfig =>
      revenueCatApiKey.isNotEmpty && isRevenueCatSupportedPlatform;
}
