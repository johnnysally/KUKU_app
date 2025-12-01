import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Lightweight in-app notification service fallback.
/// Schedules reminders while the app is running using Dart timers
/// and shows a toast when the timer fires.
class NotificationService {
  NotificationService._private();
  static final NotificationService instance = NotificationService._private();

  final Map<int, Timer> _timers = {};

  Future<void> init() async {
    // No-op for fallback implementation.
    // Timers are created when scheduling reminders while app is running.
  }

  Future<void> showNow(int id, String title, String body) async {
    // Show a toast
    await Fluttertoast.showToast(msg: '$title\n$body', toastLength: Toast.LENGTH_LONG);
    // Play the selected notification sound (if any)
    try {
      final profile = Hive.box('profile');
      final sound = profile.get('notificationSound', defaultValue: 'chime') as String;
      await _playSound(sound);
    } catch (_) {
      // ignore errors if Hive not available
    }
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playSound(String soundKey) async {
    // Map sound key to asset filename. The assets must be present under assets/sounds/.
    final map = {
      'chime': 'assets/sounds/chime.mp3',
      'bell': 'assets/sounds/bell.mp3',
      'beep': 'assets/sounds/beep.mp3',
      'note': 'assets/sounds/note.mp3',
      'melody': 'assets/sounds/melody.mp3',
      'alarm': 'assets/sounds/alarm.mp3',
    };
    final path = map[soundKey] ?? map['chime']!;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(path.replaceFirst('assets/', '')));
    } catch (_) {
      // ignore playback errors
    }
  }

  /// Play a sound preview without showing a toast — useful for settings UI.
  Future<void> previewSound(String soundKey) async {
    try {
      await _playSound(soundKey);
    } catch (_) {
      // ignore
    }
  }

  Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledDate) async {
    final now = DateTime.now();
    final diff = scheduledDate.difference(now);
    if (diff.isNegative) {
      // If time already passed, show immediately
      await showNow(id, title, body);
      return;
    }
    // Cancel existing timer with same id if any
    _timers[id]?.cancel();
    _timers[id] = Timer(diff, () async {
      await showNow(id, title, body);
      _timers.remove(id);
    });
  }

  Future<void> cancel(int id) async {
    _timers[id]?.cancel();
    _timers.remove(id);
  }

  Future<void> cancelAll() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }
}
