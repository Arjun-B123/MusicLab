package com.musiclab.musiclab

import io.flutter.embedding.android.FlutterFragmentActivity

// RevenueCat's Paywall UI (purchases_ui_flutter) renders via Android
// Fragments, which requires FlutterFragmentActivity instead of the default
// FlutterActivity — without this, presenting a paywall throws
// PAYWALLS_MISSING_WRONG_ACTIVITY.
class MainActivity : FlutterFragmentActivity()
