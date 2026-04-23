// Web key-value storage: direct browser localStorage via dart:html.
// We deliberately skip shared_preferences_web because its plugin registrant
// isn't getting compiled into our build (Flutter build-system quirk).
// localStorage has no plugin mechanism, so nothing can break.

// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String?> kvGet(String key) async => html.window.localStorage[key];

Future<void> kvSet(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<void> kvRemove(String key) async {
  html.window.localStorage.remove(key);
}
