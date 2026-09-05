import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'game_hub_screen.dart';

/// Root of the BrainBuddies educational games hub.
class BrainBuddiesApp extends StatelessWidget {
  const BrainBuddiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainBuddies',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      // Keep it phone-shaped even on wide (desktop/web) windows.
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xFF2B2B45),
          child: Center(
            child: ClipRect(
              child: SizedBox(width: 430, child: child),
            ),
          ),
        );
      },
      home: const GameHubScreen(),
    );
  }
}
