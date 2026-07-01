import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 24),
      ),
    );
    await _remoteConfig.fetchAndActivate();
  }

  bool get isAppEnabled => _remoteConfig.getBool('app_enabled');
  bool get isMaintenanceMode => _remoteConfig.getBool('maintenance_mode');
  String getString(String key) => _remoteConfig.getString(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);
  int getInt(String key) => _remoteConfig.getInt(key);
}
