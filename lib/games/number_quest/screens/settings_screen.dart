import 'package:flutter/material.dart';

import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../services/game_state.dart';

/// Settings: toggle sound and reset progress. Sound is a shared setting;
/// "Reset Everything" clears both Number Quest's progress and the shared
/// profile (coins, avatars, achievements).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state, required this.profile});

  final GameState state;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AnimatedBuilder(
              animation: profile,
              builder: (context, _) => ComicPanel(
                child: Row(
                  children: [
                    const Icon(Icons.volume_up_rounded,
                        color: AppTheme.ink, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sound & Haptics',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Switch(
                      value: profile.soundOn,
                      activeColor: AppTheme.primary,
                      onChanged: (value) {
                        profile.setSoundOn(value);
                        state.setSoundOn(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: Listenable.merge([state, profile]),
              builder: (context, _) => ComicPanel(
                color: AppTheme.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⭐ ${state.totalStars} stars   🪙 ${profile.coins} coins   '
                      'LV ${state.level}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    ComicButton(
                      label: 'Reset Everything',
                      icon: Icons.restart_alt_rounded,
                      color: AppTheme.danger,
                      fontSize: 18,
                      onPressed: () => _confirmReset(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.ink, width: 3),
        ),
        title: const Text('Reset all progress?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'This erases stars, XP, coins, avatars and awards across all games. '
          'This cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await state.reset();
              await profile.reset();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Reset',
                style: TextStyle(
                    color: AppTheme.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
