import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<Uint8List> compressImageBytes(Uint8List bytes, {int maxSide = 0}) async {
  try {
    final blob = web.Blob([bytes.toJS as JSAny].toJS);
    final url = web.URL.createObjectURL(blob);

    final img = web.HTMLImageElement();
    final completer = Completer<void>();
    void onLoad(JSAny? _) {
      if (!completer.isCompleted) completer.complete();
    }
    void onError(JSAny? _) {
      if (!completer.isCompleted) completer.completeError('img error');
    }
    img.addEventListener('load', onLoad.toJS);
    img.addEventListener('error', onError.toJS);
    img.src = url;

    await completer.future.timeout(const Duration(seconds: 5));
    web.URL.revokeObjectURL(url);

    // maxSide = 0 → resolusi asli dipertahankan (perilaku lama). Kalau diisi, sisi terpanjang
    // dibatasi supaya hasil upload-nya bisa diprediksi ukurannya; rasio tetap.
    var width = img.naturalWidth;
    var height = img.naturalHeight;
    final longest = width > height ? width : height;
    if (maxSide > 0 && longest > maxSide) {
      final scale = maxSide / longest;
      width = (width * scale).round();
      height = (height * scale).round();
    }

    final canvas = web.HTMLCanvasElement();
    canvas.width = width;
    canvas.height = height;
    final ctx = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
    ctx.drawImage(img, 0, 0, width, height);

    final dataUrl = canvas.toDataURL('image/jpeg', 0.8.toJS);
    return base64Decode(dataUrl.split(',').last);
  } catch (_) {
    return bytes;
  }
}

Future<Uint8List> compressImageFile(String path) async => Uint8List(0);
