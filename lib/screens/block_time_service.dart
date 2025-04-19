import 'dart:async';

import 'package:flutter/material.dart';

class BlockTimeService extends ChangeNotifier {
  Duration _totalBlockedDuration = Duration.zero;
  final StreamController<Duration> _streamController =
      StreamController<Duration>.broadcast();

  Duration get totalBlockedDuration => _totalBlockedDuration;
  Stream<Duration> get durationStream => _streamController.stream;

  void updateDuration(Duration newDuration) {
    _totalBlockedDuration = newDuration;
    _streamController.add(_totalBlockedDuration);
    notifyListeners();
  }

  void dispose() {
    _streamController.close();
  }
}
