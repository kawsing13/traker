import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CredentialsService {
  static final CredentialsService _instance = CredentialsService._init();
  late SharedPreferences _prefs;
  final Connectivity _connectivity = Connectivity();

  // SharedPreferences keys
  static const String _rememberMeKey = 'remember_me';
  static const String _employeeIdKey = 'saved_employee_id';
  static const String _passwordKey = 'saved_password';

  CredentialsService._init();

  static CredentialsService get instance => _instance;

  // Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Check if internet is connected
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Check if connected to mobile or wifi
      return connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  // Save login credentials (if Remember Me is enabled)
  Future<void> saveCredentials(
    String employeeId,
    String password,
    bool rememberMe,
  ) async {
    if (rememberMe) {
      await _prefs.setBool(_rememberMeKey, true);
      await _prefs.setString(_employeeIdKey, employeeId);
      await _prefs.setString(_passwordKey, password);
    } else {
      clearCredentials();
    }
  }

  // Get saved credentials
  Map<String, String>? getSavedCredentials() {
    final isRemembered = _prefs.getBool(_rememberMeKey) ?? false;
    if (!isRemembered) return null;

    final employeeId = _prefs.getString(_employeeIdKey);
    final password = _prefs.getString(_passwordKey);

    if (employeeId != null && password != null) {
      return {
        'employeeId': employeeId,
        'password': password,
      };
    }
    return null;
  }

  // Check if Remember Me is enabled
  bool isRememberMeEnabled() {
    return _prefs.getBool(_rememberMeKey) ?? false;
  }

  // Clear saved credentials
  Future<void> clearCredentials() async {
    await _prefs.remove(_rememberMeKey);
    await _prefs.remove(_employeeIdKey);
    await _prefs.remove(_passwordKey);
  }
}
