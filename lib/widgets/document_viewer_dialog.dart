// Conditional export: web gets the iframe viewer, all other platforms
// (Android, iOS, desktop) get the url_launcher-based fallback.
// All importers continue to use this file unchanged.
export 'document_viewer_mobile.dart'
    if (dart.library.html) 'document_viewer_web.dart';
