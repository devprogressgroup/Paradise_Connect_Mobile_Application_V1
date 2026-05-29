String convertDriveUrl(String url) {
  try {
    final uri = Uri.parse(url);
    if (uri.host.contains('drive.google.com')) {
      // Path: /file/d/FILE_ID/view → segments = ['file','d','FILE_ID','view']
      final id = uri.pathSegments[2];
      // thumbnail API: direct image serving, no redirect/confirmation page, CORS-safe
      return 'https://drive.google.com/thumbnail?id=$id&sz=w1000';
    }
    return url;
  } catch (e) {
    return url;
  }
}