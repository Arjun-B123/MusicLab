import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Thin wrapper around the parts of the RevenueCat SDK used for a manual
/// (non-prebuilt-paywall) purchase flow — fetching offerings/packages and
/// buying one, with RevenueCat's own error codes translated into something
/// a screen can react to sensibly.
///
/// For most screens, prefer presenting RevenueCat's own Paywall UI
/// (see paywall_helpers.dart) instead of building a custom purchase screen
/// with this — it's less code and stays in sync with whatever's configured
/// in the RevenueCat dashboard. This exists for cases where a fully custom
/// UI is worth it.
class PurchaseService {
  /// The "current" offering configured in the RevenueCat dashboard, which
  /// should contain the Lifetime / Yearly / Monthly packages for MusicLab
  /// Pro. Returns null if no offering is configured yet.
  Future<Offering?> fetchCurrentOffering() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current;
  }

  /// Looks up a package by its RevenueCat package type, matching the
  /// Lifetime / Yearly / Monthly products configured for MusicLab Pro.
  Package? packageFor(Offering offering, PackageType type) {
    for (final package in offering.availablePackages) {
      if (package.packageType == type) return package;
    }
    return null;
  }

  Future<PurchaseResult> purchase(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return PurchaseResult.success(customerInfo);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled();
      }
      return PurchaseResult.failure(_friendlyMessage(code));
    }
  }

  String _friendlyMessage(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return "Couldn't reach the store — check your connection and try again.";
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are disabled on this device (parental controls or restrictions).';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return "You already own this — try 'Restore purchases' instead.";
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment is pending approval — this will unlock automatically once approved.';
      default:
        return 'Something went wrong with the purchase. Please try again.';
    }
  }
}

class PurchaseResult {
  final bool cancelled;
  final CustomerInfo? customerInfo;
  final String? errorMessage;

  PurchaseResult._(this.cancelled, this.customerInfo, this.errorMessage);

  factory PurchaseResult.success(CustomerInfo info) =>
      PurchaseResult._(false, info, null);
  factory PurchaseResult.cancelled() => PurchaseResult._(true, null, null);
  factory PurchaseResult.failure(String message) =>
      PurchaseResult._(false, null, message);

  bool get isSuccess => !cancelled && errorMessage == null;
}
