import 'package:flutter/material.dart';

/// Penanda format caption (dipakai backend & FeedRichText): `**` = tebal, `__` = miring.
/// Setiap penanda membalik status format untuk teks sesudahnya (seperti toggle di Word).
const feedBoldMark = '**';
const feedItalicMark = '__';

/// Potongan caption mentah: penanda ([marker]) atau satu karakter teks dengan status format.
class FeedCaptionToken {
  const FeedCaptionToken(
    this.start,
    this.end, {
    this.marker = false,
    this.bold = false,
    this.italic = false,
  });

  final int start;
  final int end;
  final bool marker;
  final bool bold;
  final bool italic;
}

/// Memecah caption mentah menjadi penanda dan karakter ber-format.
/// Mendukung format bersarang, mis. `**__teks__**` = tebal + miring.
List<FeedCaptionToken> tokenizeFeedCaption(String raw) {
  final out = <FeedCaptionToken>[];
  var bold = false;
  var italic = false;
  var k = 0;
  while (k < raw.length) {
    if (raw.startsWith(feedBoldMark, k)) {
      out.add(FeedCaptionToken(k, k + 2, marker: true));
      bold = !bold;
      k += 2;
    } else if (raw.startsWith(feedItalicMark, k)) {
      out.add(FeedCaptionToken(k, k + 2, marker: true));
      italic = !italic;
      k += 2;
    } else {
      // Satu code point: emoji di luar BMP (mis. 🎉) terdiri dari 2 unit UTF-16 (surrogate pair).
      // Jika dipotong per unit, tiap surrogate tampil sebagai kotak.
      final isHighSurrogate = raw.codeUnitAt(k) >= 0xD800 && raw.codeUnitAt(k) <= 0xDBFF;
      final len = isHighSurrogate && k + 1 < raw.length ? 2 : 1;
      out.add(FeedCaptionToken(k, k + len, bold: bold, italic: italic));
      k += len;
    }
  }
  return out;
}

class _Ch {
  _Ch(this.c, this.bold, this.italic);
  final String c;
  bool bold;
  bool italic;
}

List<_Ch> _charsOf(String raw, List<FeedCaptionToken> toks) => [
  for (final t in toks)
    if (!t.marker) _Ch(raw.substring(t.start, t.end), t.bold, t.italic),
];

/// Menulis ulang caption dari daftar karakter; penanda hanya ditulis saat status format berubah.
String _serialize(List<_Ch> chars) {
  final buf = StringBuffer();
  var bold = false;
  var italic = false;
  for (final ch in chars) {
    if (ch.bold != bold) {
      buf.write(feedBoldMark);
      bold = ch.bold;
    }
    if (ch.italic != italic) {
      buf.write(feedItalicMark);
      italic = ch.italic;
    }
    buf.write(ch.c);
  }
  if (italic) buf.write(feedItalicMark);
  if (bold) buf.write(feedBoldMark);
  return buf.toString();
}

/// Jumlah unit UTF-16 tampil (tanpa penanda) sebelum posisi [rawPos] di teks mentah.
/// Dihitung per unit UTF-16 agar sejajar dengan posisi kursor TextEditingController.
int _visibleOf(List<FeedCaptionToken> toks, int rawPos) {
  var n = 0;
  for (final t in toks) {
    if (!t.marker && t.start < rawPos) n += t.end - t.start;
  }
  return n;
}

/// Posisi mentah dari posisi karakter tampil [visible] (dalam unit UTF-16).
int _rawOf(List<FeedCaptionToken> toks, int visible) {
  var n = 0;
  var last = 0;
  for (final t in toks) {
    if (t.marker) continue;
    if (n >= visible) return t.start;
    n += t.end - t.start;
    last = t.end;
  }
  return last;
}

/// Controller untuk caption yang langsung menampilkan format (seperti Word):
/// - Pilih teks lalu B/I: format diterapkan, tekan lagi untuk membatalkan.
/// - Tanpa seleksi: B/I berlaku untuk ketikan berikutnya sampai kursor dipindah.
/// - Penanda `**`/`__` disembunyikan secara visual, tetap ada di [text] (dikirim ke backend).
class FeedFormattedTextController extends TextEditingController {
  FeedFormattedTextController({super.text});

  // Format untuk ketikan berikutnya saat tanpa seleksi. null = ikut format di sekitar kursor.
  bool? _pendingBold;
  bool? _pendingItalic;

  static const _hiddenMark = TextStyle(
    fontSize: 0.1,
    color: Colors.transparent,
  );

  @override
  TextEditingValue get value => super.value;

  @override
  set value(TextEditingValue newValue) {
    final old = super.value;
    if (newValue.text == old.text) {
      // Kursor dipindah (tap/geser): format tanpa seleksi tidak berlaku lagi.
      if (newValue.selection != old.selection) {
        _pendingBold = null;
        _pendingItalic = null;
      }
      super.value = newValue;
      return;
    }
    super.value = (_pendingBold == null && _pendingItalic == null)
        ? newValue
        : _applyPendingToInsertion(old.text, newValue);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final raw = text;
    final spans = <TextSpan>[];
    final buf = StringBuffer();
    var has = false;
    var bufMarker = false;
    var bufBold = false;
    var bufItalic = false;

    void flush() {
      if (!has) return;
      spans.add(
        TextSpan(
          text: buf.toString(),
          style: bufMarker
              ? _hiddenMark
              : TextStyle(
                  fontWeight: bufBold ? FontWeight.bold : null,
                  fontStyle: bufItalic ? FontStyle.italic : null,
                ),
        ),
      );
      buf.clear();
      has = false;
    }

    for (final t in tokenizeFeedCaption(raw)) {
      final s = raw.substring(t.start, t.end);
      final same =
          has &&
          t.marker == bufMarker &&
          t.bold == bufBold &&
          t.italic == bufItalic;
      if (!same) {
        flush();
        has = true;
        bufMarker = t.marker;
        bufBold = t.bold;
        bufItalic = t.italic;
      }
      buf.write(s);
    }
    flush();
    return TextSpan(style: style, children: spans);
  }

  /// Membuat format [pending] berlaku untuk karakter yang baru diketik.
  TextEditingValue _applyPendingToInsertion(
    String oldRaw,
    TextEditingValue nv,
  ) {
    final newRaw = nv.text;
    final minLen = oldRaw.length < newRaw.length ? oldRaw.length : newRaw.length;
    var prefix = 0;
    while (prefix < minLen &&
        oldRaw.codeUnitAt(prefix) == newRaw.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < minLen - prefix &&
        oldRaw.codeUnitAt(oldRaw.length - 1 - suffix) ==
            newRaw.codeUnitAt(newRaw.length - 1 - suffix)) {
      suffix++;
    }
    final insEnd = newRaw.length - suffix;
    if (insEnd <= prefix) return nv; // hanya hapus: format tidak berubah

    final toks = tokenizeFeedCaption(newRaw);
    final chars = _charsOf(newRaw, toks);
    var idx = 0;
    for (final t in toks) {
      if (t.marker) continue;
      if (t.start >= prefix && t.end <= insEnd) {
        if (_pendingBold != null) chars[idx].bold = _pendingBold!;
        if (_pendingItalic != null) chars[idx].italic = _pendingItalic!;
      }
      idx++;
    }

    final raw = _serialize(chars);
    final caretRaw = nv.selection.baseOffset < 0
        ? newRaw.length
        : nv.selection.baseOffset;
    final caret = _rawOf(
      tokenizeFeedCaption(raw),
      _visibleOf(toks, caretRaw),
    );
    return TextEditingValue(
      text: raw,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  /// Rentang seleksi dalam satuan karakter tampil: [awal, akhir].
  List<int> _visibleRange(List<FeedCaptionToken> toks) {
    final sel = selection;
    final len = text.length;
    final s = sel.start < 0 ? len : sel.start;
    final e = sel.end < 0 ? len : sel.end;
    return [
      _visibleOf(toks, s < e ? s : e),
      _visibleOf(toks, s < e ? e : s),
    ];
  }

  void toggleBold() => _toggle(bold: true);

  void toggleItalic() => _toggle(bold: false);

  /// Apakah tombol B/I sedang aktif (untuk highlight tombol).
  bool isActive({required bool bold}) {
    final toks = tokenizeFeedCaption(text);
    final chars = _charsOf(text, toks);
    final r = _visibleRange(toks);
    if (r[0] == r[1]) {
      final pending = bold ? _pendingBold : _pendingItalic;
      if (pending != null) return pending;
      final lo = r[0];
      if (lo == 0) return false;
      return bold ? chars[lo - 1].bold : chars[lo - 1].italic;
    }
    for (var i = r[0]; i < r[1]; i++) {
      if (!(bold ? chars[i].bold : chars[i].italic)) return false;
    }
    return true;
  }

  void _toggle({required bool bold}) {
    final raw = text;
    final toks = tokenizeFeedCaption(raw);
    final chars = _charsOf(raw, toks);
    final r = _visibleRange(toks);
    final lo = r[0];
    final hi = r[1];

    if (lo == hi) {
      // Tanpa seleksi: ubah format untuk ketikan berikutnya.
      final current = lo > 0
          ? (bold ? chars[lo - 1].bold : chars[lo - 1].italic)
          : false;
      final pending = bold ? _pendingBold : _pendingItalic;
      final next = !(pending ?? current);
      if (bold) {
        _pendingBold = next;
      } else {
        _pendingItalic = next;
      }
      notifyListeners();
      return;
    }

    // Dengan seleksi: kalau semua sudah ber-format, hapus; kalau belum, terapkan.
    var allOn = true;
    for (var i = lo; i < hi; i++) {
      if (!(bold ? chars[i].bold : chars[i].italic)) {
        allOn = false;
        break;
      }
    }
    for (var i = lo; i < hi; i++) {
      if (bold) {
        chars[i].bold = !allOn;
      } else {
        chars[i].italic = !allOn;
      }
    }

    final newRaw = _serialize(chars);
    final newToks = tokenizeFeedCaption(newRaw);
    super.value = TextEditingValue(
      text: newRaw,
      selection: TextSelection(
        baseOffset: _rawOf(newToks, lo),
        extentOffset: _rawOf(newToks, hi),
      ),
    );
  }
}
