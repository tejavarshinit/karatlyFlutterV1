import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import 'augmont_api.dart';

final augmontApiProvider = Provider<AugmontApi>((ref) {
  return AugmontApi(ref.read(dioProvider));
});

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
});

class RatePoller {
  Timer? _timer;
  final AugmontApi _api;

  RatePoller(this._api);

  void start() {
    _fetch();
    _timer = Timer.periodic(AppConstants.rateCacheTtl, (_) => _fetch());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetch() async {
    try {
      await _api.fetchLiveGoldRateSnapshot(force: true);
    } catch (_) {}
  }
}
