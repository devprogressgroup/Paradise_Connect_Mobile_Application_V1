// class ApiConstants {
//   static const String baseUrl = 'http://192.168.8.21:9090/api';
//   static const String storageUrl = 'http://192.168.8.21:9090/storage';
//   static const String waServerURL = 'http://192.168.8.40:3000';
// }

class ApiConstants {
  static const String baseUrl = 'http://192.168.8.38:8000/api';
  static const String storageUrl = 'http://192.168.8.38:8000/storage';
  static const String serverUrl = 'http://192.168.8.38:8000';
  static const String waServerURL = 'http://192.168.8.38:3000';

  static const String paradiseUrl = 'https://paradise.co.id';


  static String townshipImageUrl(String slug, String fileName) => '$paradiseUrl/bin/db/images/township/$slug/$fileName';

  static String clusterImageUrl(String townshipSlug, String fileName) => '$paradiseUrl/bin/db/images/cluster/$townshipSlug/$fileName';

  static String commercialImageUrl(String filePath) => filePath.startsWith('bin/db/') ? '$paradiseUrl/$filePath' : '$paradiseUrl/bin/db/images/commercial/$filePath';
}

