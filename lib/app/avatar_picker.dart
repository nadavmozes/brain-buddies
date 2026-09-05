import 'package:flutter/material.dart';

import '../core/models/avatar.dart';
import '../core/services/feedback_service.dart';
import '../core/services/player_profile.dart';
import '../core/theme/app_theme.dart';
import 'shop_screen.dart';

/// A quick picker to switch between owned avatars. Opened by tapping the
/// avatar in the profile bar. Offers a shortcut to the shop for more.
Future<void> showAvatarPicker(BuildContext context, PlayerProfile profile) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final owned =
          Avatars.all.where((a) => profile.ownsAvatar(a.id)).toList();
      return AlertDialog(
        backgroundColor: AppTheme.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.ink, width: 3),
        ),
        title: const Text('Choose your avatar',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: AnimatedBuilder(
            animation: profile,
            builder: (context, _) => Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final a in owned)
                  _PickTile(
                    avatar: a,
                    selected: profile.selectedAvatarId == a.id,
                    onTap: () {
                      profile.selectAvatar(a.id);
                      FeedbackService(enabled: profile.soundOn).correct();
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ShopScreen(profile: profile)),
              );
            },
            child: const Text('Get more',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      );
    },
  );
}

class _PickTile extends StatelessWidget {
  const _PickTile(
      {required this.avatar, required this.selected, required this.onTap});

  final Avatar avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: avatar.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.success : AppTheme.ink,
            width: selected ? 4 : 2.5,
          ),
        ),
        child: Text(avatar.emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }
}
