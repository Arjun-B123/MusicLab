import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/app_config.dart';

/// App-wide subscription state, sourced from RevenueCat's CustomerInfo.
///
/// Exposed via Provider so any screen can check [isPro] without talking to
/// the RevenueCat SDK directly. Updates automatically whenever RevenueCat
/// reports a change (new purchase, renewal, expiration, restore) via its
/// customer info listener — no manual refresh needed.
class SubscriptionStatus extends ChangeNotifier {
  CustomerInfo? _customerInfo;
  bool _isInitialized = false;
  Object? _lastError;

  CustomerInfo? get customerInfo => _customerInfo;
  bool get isInitialized => _isInitialized;
  Object? get lastError => _lastError;

  bool get isPro =>
      _customerInfo?.entitlements.active.containsKey(
        AppConfig.proEntitlementId,
      ) ??
      false;

  /// Call once, after `Purchases.configure` has run in main().
  Future<void> initialize() async {
    if (!AppConfig.hasRevenueCatConfig) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      _lastError = e;
    }

    _isInitialized = true;
    notifyListeners();

    Purchases.addCustomerInfoUpdateListener((info) {
      _customerInfo = info;
      notifyListeners();
    });
  }

  Future<void> restorePurchases() async {
    _customerInfo = await Purchases.restorePurchases();
    notifyListeners();
  }
}
