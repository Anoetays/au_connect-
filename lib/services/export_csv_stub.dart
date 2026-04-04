// Stub implementation for non-web platforms.

class ExportCsv {
  static void downloadCsv(String csvContent, String filename) {
    // Non-web: no direct file download capability via browser API.
    throw UnsupportedError('CSV download is only available on web.');
  }
}
