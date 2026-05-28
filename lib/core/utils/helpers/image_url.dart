String convertDriveUrl(String url) {
  try {
    final uri = Uri.parse(url);
    // Path: /file/d/FILE_ID/view → segments = ['file','d','FILE_ID','view']
    final id = uri.pathSegments[2];
    // thumbnail API: direct image serving, no redirect/confirmation page, CORS-safe
    return 'https://drive.google.com/thumbnail?id=$id&sz=w1000';
  } catch (e) {
    return url;
  }
}