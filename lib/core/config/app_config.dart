/// Runtime configuration, supplied via --dart-define at build/run time so
/// real keys never get hardcoded or committed to the repo.
///
/// Example:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=xxxx \
///     --dart-define=REVENUECAT_API_KEY=xxxx
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const revenueCatApiKey = String.fromEnvironment('REVENUECAT_API_KEY');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasRevenueCatConfig => revenueCatApiKey.isNotEmpty;
}
