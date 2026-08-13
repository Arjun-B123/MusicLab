import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Ensures there's a signed-in Supabase user before the app needs one.
///
/// No login screen exists yet, so every install is bootstrapped with an
/// anonymous Supabase user — private and persistent on this device, and
/// upgradeable to a real email/social account later without losing data.
/// This unblocks row-level-security-protected data (pieces, recordings,
/// diary entries) without forcing a signup flow before Milestone 2 needs it.
Future<void> ensureSignedIn() async {
  if (!AppConfig.hasSupabaseConfig) return;

  final auth = Supabase.instance.client.auth;
  if (auth.currentSession != null) return;

  await auth.signInAnonymously();
}
