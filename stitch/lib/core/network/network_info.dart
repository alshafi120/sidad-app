/// Network connectivity monitoring.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Service Provider ──────────────────────────────────────────────────
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(Connectivity());
});

// ── Interface ────────────────────────────────────────────────────────
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

// ── Implementation ───────────────────────────────────────────────────
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl(this._connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (result) => _isConnected(result),
    );
  }

  bool _isConnected(List<ConnectivityResult> results) {
    // If the list contains mobile, wifi, ethernet, or vpn, we assume connected.
    // Starting with connectivity_plus ^6.0.0, checkConnectivity returns a List<ConnectivityResult>.
    if (results.contains(ConnectivityResult.none)) {
      // if the only result is none
      if (results.length == 1) return false;
    }
    return results.any(
      (element) =>
          element == ConnectivityResult.mobile ||
          element == ConnectivityResult.wifi ||
          element == ConnectivityResult.ethernet ||
          element == ConnectivityResult.vpn,
    );
  }
}
