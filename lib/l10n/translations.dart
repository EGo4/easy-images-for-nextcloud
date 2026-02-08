import 'package:flutter/widgets.dart';
import '../app_locale.dart';

const Map<String, Map<String, String>> _translations = {
  'en': {
    'app_title': 'Nextcloud Uploader',
    'camera': 'Camera',
    'gallery': 'Gallery',
    'select_folder': 'Select this Folder',
    'nextcloud': 'Nextcloud',
    'destination': 'Destination:',
    'confirm_upload': 'Confirm Upload',
    'select_more': 'Select more',
    'upload_files': 'Upload {count} files',
    'no_images_selected': 'No images selected',
    'uploading_percent': 'Uploading {pct}%',
    'all_files_uploaded': 'All files uploaded successfully!',
    'settings': 'Settings',
    'nextcloud_server_url': 'Nextcloud server URL',
    'username': 'Username',
    'password': 'Password',
    'default_upload_path': 'Default upload path',
    'save': 'Save',
  },
  'de': {
    'app_title': 'Nextcloud Hochlader',
    'camera': 'Kamera',
    'gallery': 'Galerie',
    'select_folder': 'Ordner wählen',
    'nextcloud': 'Nextcloud',
    'destination': 'Ziel:',
    'confirm_upload': 'Upload bestätigen',
    'select_more': 'Weitere auswählen',
    'upload_files': 'Upload von {count} Dateien',
    'no_images_selected': 'Keine Bilder ausgewählt',
    'uploading_percent': 'Hochladen {pct}%',
    'all_files_uploaded': 'Alle Dateien erfolgreich hochgeladen!',
    'settings': 'Einstellungen',
    'nextcloud_server_url': 'Nextcloud Server-URL',
    'username': 'Benutzername',
    'password': 'Passwort',
    'default_upload_path': 'Standard Upload-Pfad',
    'save': 'Speichern',
  },
};

String t(BuildContext context, String key, {Map<String, String>? args}) {
  final code = appLocale.value?.languageCode ?? 'en';
  final map = _translations[code] ?? _translations['en']!;
  var value = map[key] ?? _translations['en']![key] ?? key;
  args?.forEach((k, v) {
    value = value.replaceAll('{$k}', v);
  });
  return value;
}
