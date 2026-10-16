import 'package:equatable/equatable.dart';

/// Kuesioner customer reserve order (`questionnaire` di detail) — form & isinya sama dgn form
/// Edit Customer Reserve web (`CustomerReserveQuestionnaire` di backend). Disimpan lewat
/// `POST /reserve-order/questionnaire/{id}` dgn body `questioner[<name>]`.
class ReserveQuestionnaireEntity extends Equatable {
  final List<ReserveQuestionEntity> questions;

  /// Tanggal kuesioner PERTAMA kali diisi (diisi sistem), null = belum pernah.
  final String? filledDate;

  const ReserveQuestionnaireEntity({
    this.questions = const [],
    this.filledDate,
  });

  /// Nilai tersimpan input [name] ('' kalau kosong / tidak ada).
  String valueOf(String name) {
    for (final q in questions) {
      for (final input in q.inputs) {
        if (input.name == name) return input.value;
      }
    }
    return '';
  }

  @override
  List<Object?> get props => [questions, filledDate];
}

/// Satu pertanyaan. `layout` 'table' = tabel ber-header [head], 1 baris per [ReserveQuestionInputEntity.row].
/// [dependsName]/[dependsValue] = hanya tampil kalau input [dependsName] bernilai [dependsValue].
class ReserveQuestionEntity extends Equatable {
  final String title;
  final String? text;
  final String layout;
  final List<String> head;
  final String? dependsName;
  final String? dependsValue;

  /// Ringkasan jawaban dari server utk tampilan baca (1 baris per isian), null = belum dijawab.
  final String? answer;
  final List<ReserveQuestionInputEntity> inputs;

  const ReserveQuestionEntity({
    required this.title,
    this.text,
    this.layout = 'fields',
    this.head = const [],
    this.dependsName,
    this.dependsValue,
    this.answer,
    this.inputs = const [],
  });

  bool get isTable => layout == 'table';

  /// Tampil? — pertanyaan bersyarat hanya kalau input [dependsName] bernilai [dependsValue].
  /// [valueOf] = nilai input saat ini per `name`.
  bool isVisible(String Function(String name) valueOf) =>
      dependsName == null || valueOf(dependsName!) == dependsValue;

  @override
  List<Object?> get props => [
    title,
    text,
    layout,
    head,
    dependsName,
    dependsValue,
    answer,
    inputs,
  ];
}

/// Satu isian. [type]: `text` / `int` (isian; [toggle] = label centang di depannya, isian aktif
/// selama dicentang), `check` (centang, nilai '1'), `radio` / `pick` (pilih satu dari [options];
/// radio ber-[moreLabel] punya pilihan "Lebih dari 3" bernilai 'more' + angka di [moreValue]).
class ReserveQuestionInputEntity extends Equatable {
  final String name;
  final String type;
  final String? label;
  final String? toggle;
  final String? placeholder;
  final int? max;
  final String? row;
  final String value;
  final String moreValue;
  final List<ReserveQuestionOptionEntity> options;
  final String? moreLabel;
  final int? moreMin;

  const ReserveQuestionInputEntity({
    required this.name,
    required this.type,
    this.label,
    this.toggle,
    this.placeholder,
    this.max,
    this.row,
    this.value = '',
    this.moreValue = '',
    this.options = const [],
    this.moreLabel,
    this.moreMin,
  });

  bool get isText => type == 'text' || type == 'int';
  bool get isChoice => type == 'radio' || type == 'pick';

  @override
  List<Object?> get props => [
    name,
    type,
    label,
    toggle,
    placeholder,
    max,
    row,
    value,
    moreValue,
    options,
    moreLabel,
    moreMin,
  ];
}

class ReserveQuestionOptionEntity extends Equatable {
  final String value;
  final String label;

  const ReserveQuestionOptionEntity({required this.value, required this.label});

  @override
  List<Object?> get props => [value, label];
}
