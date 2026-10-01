import 'package:shared_preferences/shared_preferences.dart';

class DeviceUsageService {
  static const String _usageKey =
      'gvam_device_manager_usage_state';

  Future<String> getState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usageKey) ?? 'idle';
  }

  Future<bool> isIdle() async {
    return (await getState()) == 'idle';
  }

  Future<void> markIdle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usageKey, 'idle');
  }

  Future<void> markInUse() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usageKey, 'in_use');
  }
}
