import 'package:flutter/material.dart';

import '../core/models/game_catalog.dart';
import '../core/services/feedback_email.dart';
import '../core/services/player_profile.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/coin_pill.dart';
import '../core/widgets/comic_panel.dart';
import '../games/clock_hero/screens/clock_hero_home_screen.dart';
import '../games/clock_hero/services/clock_state.dart';
import '../games/number_quest/screens/number_quest_home_screen.dart';
import '../games/number_quest/services/game_state.dart';
import '../games/shape_safari/screens/shape_safari_home_screen.dart';
import '../games/shape_safari/services/safari_state.dart';
import '../games/word_wizard/screens/word_wizard_home_screen.dart';
import '../games/word_wizard/services/wizard_state.dart';
import 'achievements_screen.dart';
import 'avatar_picker.dart';
import 'shop_screen.dart';

/// The BrainBuddies home: a shared profile bar, a grid of games, and hub-level
/// actions (Shop, Achievements) that use the shared [PlayerProfile].
class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  // Shared across all games. Created and loaded once here.
  final PlayerProfile _profile = PlayerProfile();
  bool _profileReady = false;

  // Each game's per-game progress state, loaded lazily on first open.
  GameState? _numberQuestState;
  SafariState? _safariState;
  WizardState? _wizardState;
  ClockState? _clockState;

  @override
  void initState() {
    super.initState();
    _profile.load().then((_) {
      if (mounted) setState(() => _profileReady = true);
    });
  }

  Future<void> _openNumberQuest() async {
    _numberQuestState ??= GameState();
    if (!_numberQuestState!.isLoaded) {
      await _numberQuestState!.load();
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NumberQuestHome(state: _numberQuestState!, profile: _profile),
      ),
    );
  }

  Future<void> _openShapeSafari() async {
    _safariState ??= SafariState();
    if (!_safariState!.isLoaded) {
      await _safariState!.load();
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ShapeSafariHome(state: _safariState!, profile: _profile),
      ),
    );
  }

  Future<void> _openWordWizard() async {
    _wizardState ??= WizardState();
    if (!_wizardState!.isLoaded) {
      await _wizardState!.load();
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WordWizardHome(state: _wizardState!, profile: _profile),
      ),
    );
  }

  Future<void> _openClockHero() async {
    _clockState ??= ClockState();
    if (!_clockState!.isLoaded) {
      await _clockState!.load();
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClockHeroHome(state: _clockState!, profile: _profile),
      ),
    );
  }

  void _openShop() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShopScreen(profile: _profile)),
    );
  }

  void _openAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => AchievementsScreen(profile: _profile)),
    );
  }

  void _onTap(GameEntry game) {
    if (!game.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${game.title} is coming soon! 🚧')),
      );
      return;
    }
    if (game.id == GameCatalog.numberQuest.id) {
      _openNumberQuest();
    } else if (game.id == GameCatalog.shapeSafari.id) {
      _openShapeSafari();
    } else if (game.id == GameCatalog.wordWizard.id) {
      _openWordWizard();
    } else if (game.id == GameCatalog.clockHero.id) {
      _openClockHero();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.sky, AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              if (_profileReady)
                _ProfileBar(
                  profile: _profile,
                  onTapAvatar: () => showAvatarPicker(context, _profile),
                ),
              const SizedBox(height: 12),
              const _HubTitle(),
              const SizedBox(height: 6),
              const Text(
                'Pick a game and start learning!',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.82,
                  children: [
                    for (final game in GameCatalog.all)
                      _GameCard(game: game, onTap: () => _onTap(game)),
                  ],
                ),
              ),
              if (_profileReady) _hubActions(),
              const SizedBox(height: 8),
              _Footer(onFeedback: () => FeedbackEmail.open(context)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hubActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Shop',
              emoji: '🛍️',
              onTap: _openShop,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ActionButton(
              label: 'Awards',
              emoji: '🏆',
              onTap: _openAchievements,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the equipped avatar (tap to change) and shared coin balance.
class _ProfileBar extends StatelessWidget {
  const _ProfileBar({required this.profile, required this.onTapAvatar});

  final PlayerProfile profile;
  final VoidCallback onTapAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: profile,
        builder: (_, __) => Row(
          children: [
            GestureDetector(
              onTap: onTapAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: profile.selectedAvatar.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.ink, width: 2.5),
                    ),
                    child: Text(profile.selectedAvatar.emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                  // Small edit badge hinting the avatar is tappable.
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.ink, width: 1.5),
                      ),
                      child: const Icon(Icons.edit,
                          size: 10, color: AppTheme.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(profile.selectedAvatar.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const Spacer(),
            CoinPill(amount: profile.coins),
          ],
        ),
      ),
    );
  }
}

/// Hub footer: an "AI-made" disclosure on the left and a Feedback button
/// (opens the mail app) on the right.
class _Footer extends StatelessWidget {
  const _Footer({required this.onFeedback});

  final VoidCallback onFeedback;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Made with AI 🤖',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ),
          GestureDetector(
            onTap: onFeedback,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.ink, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_outline_rounded,
                      size: 16, color: AppTheme.ink),
                  SizedBox(width: 6),
                  Text('Feedback',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.label, required this.emoji, required this.onTap});

  final String label;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ComicPanel(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onTap});

  final GameEntry game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: game.available ? 1 : 0.6,
        child: ComicPanel(
          color: game.color,
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(game.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 6),
              Text(
                game.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: AppTheme.ink, offset: Offset(1.5, 1.5))],
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  game.tagline,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: game.available ? AppTheme.accent : Colors.white,
                  border: Border.all(color: AppTheme.ink, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  game.available ? 'PLAY' : 'SOON',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubTitle extends StatelessWidget {
  const _HubTitle();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.02,
      child: ComicPanel(
        color: AppTheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('🧠', style: TextStyle(fontSize: 30)),
            SizedBox(width: 8),
            Text(
              'BrainBuddies',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
                shadows: [Shadow(color: AppTheme.ink, offset: Offset(2.5, 2.5))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
