import 'package:flutter/widgets.dart';

import 'app_lang.dart';
import 'app_strings.dart';
import 'localized_catalog.dart';

export 'app_lang.dart';
export 'app_strings.dart';
export 'localized_catalog.dart';

/// Carries the current [AppLang] + resolved [AppStrings] down the tree.
///
/// An [InheritedNotifier] over the app's language source (the `PlayerProfile`,
/// which is a [Listenable]) so that toggling the language rebuilds dependents
/// live. Read it with `context.l10n` / `context.lang`.
class L10n extends InheritedNotifier<Listenable> {
  const L10n({
    super.key,
    required this.lang,
    required Listenable notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// The currently selected language.
  final AppLang lang;

  /// The resolved chrome strings for [lang].
  AppStrings get strings => stringsFor(lang == AppLang.he);

  /// Resolves a localized data-catalog string by [domain]+[key], falling back
  /// to the existing English [fallback]. See [LocalizedCatalog].
  String tr(String domain, String key, String fallback) =>
      LocalizedCatalog.resolve(domain, key, fallback, lang: lang);

  /// A fallback used when no [L10n] ancestor exists (e.g. a widget pumped
  /// directly in a test, or a screen shown before the app wraps it). Defaults
  /// to English + LTR, matching the app's default language, so localized
  /// widgets degrade gracefully instead of throwing.
  static const L10n _fallback =
      L10n(lang: AppLang.en, notifier: _NeverNotifies(), child: SizedBox());

  static L10n of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<L10n>() ?? _fallback;
  }

  /// Non-listening lookup (does not subscribe the caller to changes). Useful
  /// outside build, e.g. in callbacks that read the language once.
  static L10n read(BuildContext context) {
    final n =
        context.getElementForInheritedWidgetOfExactType<L10n>()?.widget as L10n?;
    return n ?? _fallback;
  }

  @override
  bool updateShouldNotify(L10n oldWidget) =>
      lang != oldWidget.lang || super.updateShouldNotify(oldWidget);
}

/// A const, no-op [Listenable] used only for [L10n._fallback] (which is never
/// mounted; it just carries the default English language).
class _NeverNotifies implements Listenable {
  const _NeverNotifies();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

/// Terse access to the localized strings + language from a [BuildContext].
extension L10nContext on BuildContext {
  /// The resolved chrome strings for the current language.
  AppStrings get l10n => L10n.of(this).strings;

  /// The current language.
  AppLang get lang => L10n.of(this).lang;

  /// Whether the UI is currently right-to-left (Hebrew).
  bool get isRtl => lang.isRtl;

  /// Resolves a localized data-catalog string by [domain]+[key], falling back
  /// to the existing English [fallback] when English is selected or no Hebrew
  /// translation exists. See [LocalizedCatalog].
  String tr(String domain, String key, String fallback) =>
      LocalizedCatalog.resolve(domain, key, fallback, lang: lang);
}
