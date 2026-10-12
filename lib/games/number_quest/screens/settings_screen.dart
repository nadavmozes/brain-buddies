import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
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
        title: Text(context.l10n.settings,
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
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
                    Expanded(
                      child: Text(
                        context.l10n.soundAndHaptics,
                        style: const TextStyle(
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
            // Language toggle, mirroring the hub's EN ⇄ עב pill (§5.1).
            AnimatedBuilder(
              animation: profile,
              builder: (context, _) => ComicPanel(
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded,
                        color: AppTheme.ink, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.language,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => profile.setLang(profile.lang == AppLang.en
                          ? AppLang.he
                          : AppLang.en),
                      child: Container(
                        constraints: const BoxConstraints(
                            minWidth: 56, minHeight: 36),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          border:
                              Border.all(color: AppTheme.ink, width: 2.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          profile.lang == AppLang.en
                              ? context.l10n.languageHebrew
                              : context.l10n.languageEnglish,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
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
                      '⭐ ${state.totalStars} ${context.l10n.stars}   '
                      '🪙 ${profile.coins} ${context.l10n.coins}   '
                      '${context.l10n.levelAbbrev(state.level)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    ComicButton(
                      label: context.l10n.resetEverything,
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
    final l = context.l10n;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.ink, width: 3),
        ),
        title: Text(l.resetConfirmTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          l.resetConfirmBody,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () async {
              await state.reset();
              await profile.reset();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: Text(l.reset,
                style: const TextStyle(
                    color: AppTheme.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
