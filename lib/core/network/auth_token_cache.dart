class AuthTokenCache {
  static String? _cachedToken;

  static String? get token => _cachedToken;

  static void setToken(String? token) {
    _cachedToken = token;
  }

  static Map<String, String> getAuthHeadersFor(String? url) {
    if (url != null && url.contains('/api/marketing-feed/media/') && _cachedToken != null && _cachedToken!.isNotEmpty) {
      return {
        'Authorization': 'Bearer $_cachedToken',
      };
    }
    return {};
  }
}
