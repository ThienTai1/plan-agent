import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus {
  online,
  offline,
}

final connectivityProvider = StreamProvider.autoDispose<ConnectivityStatus>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  });
});
