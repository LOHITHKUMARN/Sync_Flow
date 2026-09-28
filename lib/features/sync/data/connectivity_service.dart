import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../domain/network_status.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final _statusController = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isSimulatedOffline = false;
  NetworkStatus _currentStatus = NetworkStatus.online;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  bool get isSimulatedOffline => _isSimulatedOffline;
  NetworkStatus get currentStatus => _currentStatus;
  Stream<NetworkStatus> get onStatusChanged => _statusController.stream;

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityResults(results);
    } catch (_) {
      _currentStatus = NetworkStatus.online;
      _statusController.add(_currentStatus);
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityResults(results);
    });
  }

  void _handleConnectivityResults(List<ConnectivityResult> results) {
    if (_isSimulatedOffline) {
      _updateStatus(NetworkStatus.offline);
      return;
    }

    final isOffline = results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);

    _updateStatus(isOffline ? NetworkStatus.offline : NetworkStatus.online);
  }

  void toggleSimulatedOffline() {
    setSimulatedOffline(!_isSimulatedOffline);
  }

  void setSimulatedOffline(bool simulatedOffline) {
    _isSimulatedOffline = simulatedOffline;
    if (_isSimulatedOffline) {
      _updateStatus(NetworkStatus.offline);
    } else {
      _updateStatus(NetworkStatus.online);
      _connectivity.checkConnectivity().then((results) {
        _handleConnectivityResults(results);
      }).catchError((_) {});
    }
  }

  void setNetworkStatus(NetworkStatus status) {
    _updateStatus(status);
  }


  void _updateStatus(NetworkStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(_currentStatus);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
