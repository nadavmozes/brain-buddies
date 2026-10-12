import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/l10n.dart';
import '../core/services/analytics_service.dart';
import '../core/services/player_profile.dart';
import '../core/theme/app_theme.dart';
import 'game_hub_screen.dart';

/// Root of the BrainBuddies educational games hub.
///
/// Owns the shared [PlayerProfile] (lifted up from the hub so the UI language
/// can drive `MaterialApp.locale`) and the local-only analytics sink. An
/// [AnimatedBuilder] over the profile rebuilds [MaterialApp] when the language
/// toggles, flipping strings + `Directionality` (RTL for Hebrew) live.
class BrainBuddiesApp extends StatefulWidget {
  const BrainBuddiesApp({super.key});

  @override
  State<BrainBuddiesApp> createState() => _BrainBuddiesAppState();
}

class _BrainBuddiesAppState extends State<BrainBuddiesApp> {
  // Shared across all games. Created and loaded once here (was previously in
  // GameHubScreen; moved up so language can drive the app locale).
  final PlayerProfile _profile = PlayerProfile();
  // Local-only analytics sink, attached to the profile once at startup.
  final AnalyticsService _analytics = AnalyticsService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _profile.load().then((_) async {
      await _analytics.load();
      _profile.attachAnalytics(_analytics);
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _profile,
      builder: (context, _) {
        final lang = _profile.lang;
        return MaterialApp(
          title: 'BrainBuddies',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(lang),
          locale: lang.locale,
          supportedLocales: const [Locale('en'), Locale('he')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Keep it phone-shaped even on wide (desktop/web) windows, and expose
          // the localized strings to the whole tree via L10n.
          builder: (context, child) {
            return ColoredBox(
              color: const Color(0xFF2B2B45),
              child: Center(
                child: ClipRect(
                  child: SizedBox(
                    width: 430,
                    child: L10n(
                      lang: lang,
                      notifier: _profile,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            );
          },
          home: _ready
              ? GameHubScreen(profile: _profile, analytics: _analytics)
              : const _BootScreen(),
        );
      },
    );
  }
}

/// A minimal splash shown while the shared profile loads.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.paper,
      body: Center(child: Text('🧠', style: TextStyle(fontSize: 48))),
    );
  }
}
