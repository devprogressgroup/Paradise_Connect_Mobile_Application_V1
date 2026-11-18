import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Pemutar YouTube inline seperti video postingan: autoplay (tanpa suara) saat kartu terlihat,
/// di-pause saat keluar layar, dan tap untuk play/pause. Memakai iframe YouTube di dalam WebView.
class FeedYoutubePlayer extends StatefulWidget {
  final String videoId;

  /// false = kartu keluar layar, video di-pause. Saat kembali true, diputar lagi.
  final bool visible;

  /// Tampilan sebelum video mulai (thumbnail), juga muncul di belakang WebView.
  final Widget poster;

  const FeedYoutubePlayer({
    super.key,
    required this.videoId,
    required this.visible,
    required this.poster,
  });

  @override
  State<FeedYoutubePlayer> createState() => _FeedYoutubePlayerState();
}

class _FeedYoutubePlayerState extends State<FeedYoutubePlayer> {
  late final WebViewController _controller;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Tahan navigasi halaman utama supaya WebView tidak pindah ke situs lain.
          onNavigationRequest: (request) {
            final allowed = !request.isMainFrame ||
                request.url.startsWith('about:') ||
                request.url.startsWith('https://www.youtube.com');
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_html(widget.videoId), baseUrl: 'https://www.youtube.com');
  }

  @override
  void didUpdateWidget(covariant FeedYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _command('playVideo');
      setState(() => _playing = true);
    } else {
      _command('pauseVideo');
      setState(() => _playing = false);
    }
  }

  static String _html(String videoId) => '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body { margin: 0; height: 100%; background: #000; overflow: hidden; }
  iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe id="yt" allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen
  src="https://www.youtube.com/embed/$videoId?autoplay=1&mute=1&playsinline=1&enablejsapi=1&controls=0&rel=0&modestbranding=1"></iframe>
</body>
</html>
''';

  /// Kirim perintah ke player YouTube lewat postMessage (YouTube IFrame API).
  void _command(String func) {
    _controller.runJavaScript(
      "document.getElementById('yt').contentWindow.postMessage("
      "'{\"event\":\"command\",\"func\":\"$func\",\"args\":\"\"}', '*');",
    );
  }

  void _togglePlay() {
    _command(_playing ? 'pauseVideo' : 'playVideo');
    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.poster,
        WebViewWidget(controller: _controller),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _togglePlay,
          child: Center(
            child: AnimatedOpacity(
              opacity: _playing ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
