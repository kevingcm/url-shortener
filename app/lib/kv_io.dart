// Mobile/desktop key-value storage: shared_preferences (which works fine on
// these platforms — the native FlutterEngine registers the plugin directly).

import 'package:shared_preferences/shared_preferences.dart';

Future<String?> kvGet(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<void> kvSet(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<void> kvRemove(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}
