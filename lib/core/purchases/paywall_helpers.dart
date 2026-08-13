import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../config/app_config.dart';

/// Presents RevenueCat's hosted Paywall UI, configured and designed in the
/// RevenueCat dashboard rather than hand-built here — this is RevenueCat's
/// current recommended approach (over building a custom purchase screen)
/// since the paywall's design/copy/pricing display can be iterated on
/// remotely without an app update.
///
/// Only shows the paywall if the user doesn't already have the entitlement
/// (RevenueCat checks this for us). Returns true if the user ends up
/// entitled to MusicLab Pro after this call (via purchase or restore).
Future<bool> presentProPaywallIfNeeded(BuildContext context) async {
  final result = await RevenueCatUI.presentPaywallIfNeeded(
    AppConfig.proEntitlementId,
  );

  switch (result) {
    case PaywallResult.purchased:
    case PaywallResult.restored:
      return true;
    case PaywallResult.cancelled:
    case PaywallResult.error:
    case PaywallResult.notPresented:
      return false;
  }
}

/// Presents RevenueCat's Customer Center — a self-serve hub for the user to
/// view/manage their subscription, get help, or cancel, without needing a
/// custom "manage subscription" screen built and maintained here.
Future<void> presentCustomerCenter(BuildContext context) async {
  await RevenueCatUI.presentCustomerCenter();
}
