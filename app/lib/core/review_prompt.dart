import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../data/providers.dart';

/// Asks for a Play Store rating once the reader has finished a few checklists.
///
/// Nothing is tracked remotely: the counter is a number in SharedPreferences
/// on this phone. The prompt appears at most once, only after the third
/// checklist is completed, and a failed/unavailable store client is silent.
abstract final class ReviewPrompt {
  static const _completedKey = 'checklists_completed';
  static const _askedKey = 'review_prompt_shown';
  static const int threshold = 3;

  static Future<void> maybeAsk(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.getBool(_askedKey) ?? false) return;

      final completed = (prefs.getInt(_completedKey) ?? 0) + 1;
      await prefs.setInt(_completedKey, completed);
      if (completed < threshold) return;

      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await prefs.setBool(_askedKey, true);
      if (!context.mounted) return;
      await review.requestReview();
    } catch (_) {
      // A store client that is missing on this device must never interrupt the
      // checklist the reader is working on.
    }
  }
}
