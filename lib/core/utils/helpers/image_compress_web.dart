import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<Uint8List> compressImageBytes(Uint8List bytes) async {
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

    final canvas = web.HTMLCanvasElement();
    canvas.width = img.naturalWidth;
    canvas.height = img.naturalHeight;
    final ctx = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
    ctx.drawImage(img, 0, 0);

    final dataUrl = canvas.toDataURL('image/jpeg', 0.8.toJS);
    return base64Decode(dataUrl.split(',').last);
  } catch (_) {
    return bytes;
  }
}

Future<Uint8List> compressImageFile(String path) async => Uint8List(0);
