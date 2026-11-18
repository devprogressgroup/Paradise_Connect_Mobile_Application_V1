export 'feed_youtube_player_web.dart'
    if (dart.library.io) 'feed_youtube_player_mobile.dart';

/// Ambil ID video dari link YouTube (watch, youtu.be, shorts, live, embed). Null kalau bukan video.
String? youtubeVideoIdFromUrl(String url) {
  final match = RegExp(
    r'(?:youtu\.be/|youtube\.com/(?:watch\?(?:.*&)?v=|embed/|shorts/|live/))([A-Za-z0-9_-]{11})',
  ).firstMatch(url);
  return match?.group(1);
}
