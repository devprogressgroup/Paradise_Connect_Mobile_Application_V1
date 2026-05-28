import 'dart:io';
import 'dart:typed_data';

class CreateVisitParams {
  final int contactId;
  final int statusProspectId;
  final int visitCount;
  final String activityDate;
  final String notes;
  final List<File>? files;
  final Uint8List? fileBytes;
  final String? fileName;
  final List<Uint8List>? filesBytesData;

  CreateVisitParams({
    required this.contactId,
    required this.statusProspectId,
    required this.visitCount,
    required this.activityDate,
    required this.notes,
    this.files,
    this.fileBytes,
    this.fileName,
    this.filesBytesData,
  });
}