import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/player_profile.dart';
import '../theme/app_theme.dart';
import 'comic_panel.dart';

/// A small, friendly moment shown on result screens: how much the shared pet
/// grew this round, plus a cheerful "Buddy grew!" banner when it leveled up or
/// reached a new stage. Renders nothing when no pet XP was earned.
class PetRoundMoment extends StatelessWidget {
  const PetRoundMoment({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    if (profile.lastRoundPetXp <= 0) return const SizedBox.shrink();

    final grew =
        profile.lastRoundPetStageChanged || profile.lastRoundPetLeveledUp;

    return ComicPanel(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(profile.petStage.emoji,
                  style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Text(context.l10n.buddy,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('+${profile.lastRoundPetXp} XP',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          if (grew) ...[
            const SizedBox(height: 10),
            _grewBanner(context),
          ],
        ],
      ),
    );
  }

  Widget _grewBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.success,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.ink, width: 2.5),
      ),
      child: Text(
        context.l10n.buddyGrew,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
      ),
    );
  }
}
