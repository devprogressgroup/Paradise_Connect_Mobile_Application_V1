const Map<String, String> _extensionToMimeType = {
  '.pdf': 'application/pdf',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.bmp': 'image/bmp',
  '.mp4': 'video/mp4',
  '.mov': 'video/quicktime',
  '.webm': 'video/webm',
  '.doc': 'application/msword',
  '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  '.xls': 'application/vnd.ms-excel',
  '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  '.zip': 'application/zip',
};

/// Ekstensi dari path URL, cuma dianggap valid kalau dikenali mime-nya
/// (banyak link download seperti Google Drive `uc?export=download` tidak
/// punya ekstensi di path sama sekali).
String? extensionFromUrl(String url) {
  final safeName = url.split('/').last.split('?').first;
  if (!safeName.contains('.')) return null;
  final ext = '.${safeName.split('.').last.toLowerCase()}';
  return _extensionToMimeType.containsKey(ext) ? ext : null;
}

String? extensionFromContentDisposition(String? contentDisposition) {
  if (contentDisposition == null || contentDisposition.isEmpty) return null;
  String? name;
  var m = RegExp(r"filename\*=UTF-8''([^;\s]+)", caseSensitive: false).firstMatch(contentDisposition);
  if (m != null) name = Uri.decodeComponent(m.group(1) ?? '');
  if (name == null) {
    m = RegExp(r'filename="([^"]+)"', caseSensitive: false).firstMatch(contentDisposition);
    if (m != null) name = m.group(1);
  }
  if (name == null) {
    m = RegExp(r'filename=([^;\s"]+)', caseSensitive: false).firstMatch(contentDisposition);
    if (m != null) name = m.group(1);
  }
  if (name == null || !name.contains('.')) return null;
  return '.${name.split('.').last.toLowerCase()}';
}

String? extensionFromContentType(String? contentType) {
  if (contentType == null) return null;
  final type = contentType.split(';').first.trim().toLowerCase();
  for (final entry in _extensionToMimeType.entries) {
    if (entry.value == type) return entry.key;
  }
  return null;
}

String mimeTypeFromExtension(String ext) => _extensionToMimeType[ext.toLowerCase()] ?? 'application/octet-stream';
