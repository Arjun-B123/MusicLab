import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_gate.dart';
import 'core/config/app_config.dart';
import 'core/purchases/subscription_status.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase and RevenueCat are only initialized once real keys are
  // supplied, so the app still runs (with those features inert) for local
  // UI work before credentials are wired up.
  if (AppConfig.hasSupabaseConfig) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    await ensureSignedIn();
  }

  final subscriptionStatus = SubscriptionStatus();
  if (AppConfig.hasRevenueCatConfig) {
    await Purchases.setLogLevel(LogLevel.info);
    await Purchases.configure(
      PurchasesConfiguration(AppConfig.revenueCatApiKey),
    );
  }
  await subscriptionStatus.initialize();

  runApp(MusicLabApp(subscriptionStatus: subscriptionStatus));
}

class MusicLabApp extends StatelessWidget {
  const MusicLabApp({super.key, required this.subscriptionStatus});

  final SubscriptionStatus subscriptionStatus;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: subscriptionStatus,
      child: MaterialApp.router(
        title: 'MusicLab',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: appRouter,
        builder: (context, child) {
          // The design's cards/rings are pixel-tuned for a phone-sized
          // layout; respect the user's system text-size preference (real
          // accessibility need) but clamp the extremes so very large or
          // very small settings don't break card layouts on smaller phones.
          final clampedScaler = MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
            child: child!,
          );
        },
      ),
    );
  }
}
