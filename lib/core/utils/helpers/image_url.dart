String convertDriveUrl(String url, {int targetWidth = 1000}) {
  try {
    final uri = Uri.parse(url);
    if (uri.host.contains('drive.google.com')) {
      // Path: /file/d/FILE_ID/view → segments = ['file','d','FILE_ID','view']
      final id = uri.pathSegments[2];
      // thumbnail API: direct image serving, no redirect/confirmation page, CORS-safe.
      // targetWidth dibuat sekecil mungkin sesuai ukuran tampil (lihat pemanggil) —
      // minta ukuran full 1000px buat thumbnail kecil boros memori decode-nya.
      return 'https://drive.google.com/thumbnail?id=$id&sz=w$targetWidth';
    }
    return url;
  } catch (e) {
    return url;
  }
}