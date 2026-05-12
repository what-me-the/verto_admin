import 'dart:io';

/// Desktop fallback — saves to the user's Downloads folder.
/// Uses USERPROFILE (Windows) / HOME (macOS/Linux) to locate Downloads.
void downloadFile(List<int> bytes, String fileName) {
  try {
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '.';
    final sep = Platform.pathSeparator;
    final downloadsDir = Directory('$home${sep}Downloads');
    final targetDir = downloadsDir.existsSync() ? downloadsDir : Directory('.');
    File('${targetDir.path}$sep$fileName').writeAsBytesSync(bytes, flush: true);
  } catch (_) {
    // ignore write errors silently
  }
}
