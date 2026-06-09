import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

web.Blob _excelBlob(Uint8List bytes) => web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
    );

void downloadPdfOnWeb(Uint8List bytes, String fileName) {
  final url = web.URL.createObjectURL(_excelBlob(bytes));
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}

void openPdfOnWeb(Uint8List bytes) {
  final url = web.URL.createObjectURL(_excelBlob(bytes));
  web.window.open(url, '_blank');
}
