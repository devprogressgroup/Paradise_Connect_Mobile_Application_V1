String convertDriveUrl(String url, {int targetWidth = 1000}) {
  try {
    final uri = Uri.parse(url);
    if (uri.host.contains('drive.google.com')) {

      final id = uri.pathSegments[2];
      return 'https://drive.google.com/thumbnail?id=$id&sz=w$targetWidth';
    }
    return url;
  } catch (e) {
    return url;
  }
}