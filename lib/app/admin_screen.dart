import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/l10n/l10n.dart';
import '../core/models/achievement.dart';
import '../core/models/pet.dart';
import '../core/services/admin_reload.dart';
import '../core/services/player_profile.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/comic_button.dart';
import '../core/widgets/comic_panel.dart';

/// A HIDDEN developer / admin panel, reached only by a long-press on the hub
/// footer (no visible button advertises it).
///
/// SECURITY POSTURE (honest, by design):
///   This tool is HIDDEN from kids, but it is NOT secure against a determined
///   adult. BrainBuddies is a client-side app (served as a public web build),
///   so anyone who knows the long-press gesture — or reads this source — can
///   open it. There is deliberately NO PIN or password: the only guard is the
///   obscure entry point plus a confirm dialog on the single destructive
///   action (Reset Everything). This is acceptable because every action here
///   only mutates the LOCAL player's own save data (coins, stars, pet, etc.);
///   nothing touches other users, a server, or real money.
class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
    required this.profile,
    required this.onResetEverything,
  });

  final PlayerProfile profile;

  /// Wipes the shared profile AND all six game stores. Owned by the hub (which
  /// holds every store), awaited fully before any page reload.
  final Future<void> Function() onResetEverything;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset ALL progress?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    // Fully persist the wipe BEFORE reloading, so the fresh page reads a clean
    // slate from shared_preferences.
    await widget.onResetEverything();
    if (kIsWeb) {
      // Web: reload the page so every screen rebuilds from the clean state.
      reloadApp();
      return; // Page is going away; no SnackBar needed.
    }
    // Non-web (and tests): no page reload, so confirm with a SnackBar.
    if (!mounted) return;
    setState(() => _busy = false);
    _snack('All progress reset.');
  }

  Future<void> _grantAllAchievements() async {
    await widget.profile.grantAll(Achievements.all.map((a) => a.id));
    _snack('Granted all achievements. 🏆');
  }

  Future<void> _add500Coins() async {
    await widget.profile.addCoins(500);
    _snack('Added 500 coins. 🪙');
  }

  Future<void> _setPetLevel10() async {
    final delta = Pet.xpForLevel(10) - widget.profile.petXp;
    if (delta > 0) await widget.profile.addPetXp(delta);
    _snack('Pet set to level ${widget.profile.petLevel}. 🐦');
  }

  Future<void> _unlockAllAvatars() async {
    // Most avatar gates read achievements; the pet-level and lifetime-coin
    // gates are covered by the "Set pet to level 10" and "Add 500 coins"
    // shortcuts. Granting every achievement unlocks the achievement-gated
    // avatars without adding new PlayerProfile mutators.
    await widget.profile.grantAll(Achievements.all.map((a) => a.id));
    _snack('Granted all achievements (unlocks avatar gates). 🧑‍🎤');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.adminTitle),
        backgroundColor: AppTheme.ink,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.sky, AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _WarningBanner(),
                      const SizedBox(height: 20),
                      const _SectionLabel('Danger zone'),
                      const SizedBox(height: 10),
                      ComicButton(
                        label: context.l10n.resetEverything,
                        icon: Icons.delete_forever_rounded,
                        color: AppTheme.danger,
                        onPressed: _busy ? null : _confirmReset,
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('Testing shortcuts'),
                      const SizedBox(height: 10),
                      ComicButton(
                        label: 'Grant all achievements',
                        icon: Icons.emoji_events_rounded,
                        color: AppTheme.primary,
                        onPressed: _busy ? null : _grantAllAchievements,
                      ),
                      const SizedBox(height: 14),
                      ComicButton(
                        label: 'Add 500 coins',
                        icon: Icons.monetization_on_rounded,
                        color: AppTheme.accent,
                        textColor: AppTheme.ink,
                        onPressed: _busy ? null : _add500Coins,
                      ),
                      const SizedBox(height: 14),
                      ComicButton(
                        label: 'Set pet to level 10',
                        icon: Icons.pets_rounded,
                        color: AppTheme.success,
                        onPressed: _busy ? null : _setPetLevel10,
                      ),
                      const SizedBox(height: 14),
                      ComicButton(
                        label: 'Unlock all avatars',
                        icon: Icons.face_rounded,
                        color: AppTheme.sky,
                        textColor: AppTheme.ink,
                        onPressed: _busy ? null : _unlockAllAvatars,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A loud warning that this is a developer-only, not-secured tool.
class _WarningBanner extends StatelessWidget {
  const _WarningBanner();

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      color: AppTheme.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Developer tools',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Hidden from kids but not secured. These actions change your local '
            'save data only. "Reset Everything" cannot be undone.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: AppTheme.ink,
      ),
    );
  }
}
