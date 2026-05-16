import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  double get transparency => _prefs.getDouble('transparency') ?? 0.8;
  set transparency(double value) => _prefs.setDouble('transparency', value);

  String get hotkeyKey => _prefs.getString('hotkey_key') ?? 'x';
  set hotkeyKey(String value) => _prefs.setString('hotkey_key', value);

  List<String> get hotkeyModifiers => _prefs.getStringList('hotkey_modifiers') ?? ['command'];
  set hotkeyModifiers(List<String> value) => _prefs.setStringList('hotkey_modifiers', value);
}
