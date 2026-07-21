bool isYoutubeUrl(String url) {
  return RegExp(
    r'(?:youtube(?:-nocookie)?\.com\/(?:watch\?v=|shorts\/|embed\/)|youtu\.be\/)[a-zA-Z0-9_-]{11}',
  ).hasMatch(url);
}
