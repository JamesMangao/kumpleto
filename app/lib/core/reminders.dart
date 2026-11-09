import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/validity.dart';
import '../models/models.dart';

/// A moment worth reminding somebody about: [daysLeft] before the document
/// stops being valid.
@immutable
class ReminderMoment {
  const ReminderMoment({required this.daysLeft, required this.when});

  final int daysLeft;
  final DateTime when;
}

/// The days before expiry the app warns about, at 09:00 local time.
const List<int> reminderLeadDays = [30, 7, 1];

/// When to remind about a document that expires on [until].
///
/// Pure on purpose: the schedule is the part worth testing, and it never
/// depends on a plugin or a clock beyond [now]. Moments already in the past
/// are dropped so re-opening the app never fires a backlog at once.
List<ReminderMoment> reminderMoments(DateTime until, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final expiry = DateTime(until.year, until.month, until.day);
  final moments = <ReminderMoment>[
    for (final days in reminderLeadDays)
      ReminderMoment(
        daysLeft: days,
        when: DateTime(expiry.year, expiry.month, expiry.day - days, 9),
      ),
  ];
  return [
    for (final moment in moments)
      if (moment.when.isAfter(reference)) moment,
  ];
}

typedef ReminderTitle = String Function(Document document, int daysLeft);
typedef ReminderBody = String Function(Document document, DateTime until);

/// Schedules the expiry reminders.
///
/// The scheduler is deliberately quiet: on a platform without the plugin (the
/// desktop test run, web) or when the OS refuses, every method returns without
/// throwing, because a missing reminder must never break the checklist.
class ReminderScheduler {
  ReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'expiry_reminders';

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialised = false;
  bool _available = false;

  /// Only the mobile builds have a notification plugin we can rely on.
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<bool> init() async {
    if (_initialised) return _available;
    _initialised = true;
    if (!supported) return _available = false;
    try {
      tz_data.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _available = true;
    } catch (error) {
      debugPrint('Expiry reminders unavailable: $error');
      _available = false;
    }
    return _available;
  }

  /// Asks the OS for permission (Android 13+ and iOS need it explicitly).
  Future<bool> requestPermission() async {
    if (!await init()) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (error) {
      debugPrint('Expiry reminders permission failed: $error');
    }
    return false;
  }

  /// Replaces every scheduled reminder with the current one.
  ///
  /// Cancelling first keeps the queue honest: a document that was un-marked, or
  /// a date that moved, must not keep an old alarm.
  Future<void> sync({
    required bool enabled,
    required List<Document> documents,
    required Map<String, DateTime> acquired,
    required ReminderTitle title,
    required ReminderBody body,
  }) async {
    if (!await init()) return;
    try {
      await _plugin.cancelAll();
      if (!enabled) return;
      final now = DateTime.now();
      for (final document in documents) {
        final acquiredAt = acquired[document.id];
        final until = validUntilOf(document, acquiredAt);
        if (until == null) continue;
        for (final moment in reminderMoments(until, now: now)) {
          await _plugin.zonedSchedule(
            id: _notificationId(document.id, moment.daysLeft),
            title: title(document, moment.daysLeft),
            body: body(document, until),
            scheduledDate: tz.TZDateTime.from(moment.when, tz.local),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                channelId,
                'Document expiry',
                channelDescription: 'Reminders before a document you marked as acquired expires.',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    } catch (error) {
      debugPrint('Expiry reminder sync failed: $error');
    }
  }

  Future<void> cancelAll() async {
    if (!await init()) return;
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('Expiry reminder cancel failed: $error');
    }
  }
}

/// A small stable id: FNV-1a over the document id, plus the lead time, so the
/// same document always replaces its own reminder instead of stacking.
int _notificationId(String documentId, int daysLeft) {
  var hash = 0x811c9dc5;
  for (final unit in documentId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return (hash % 2000000) * 10 + daysLeft;
}
