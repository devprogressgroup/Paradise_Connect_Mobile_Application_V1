import 'dart:io';

import 'dart:typed_data';

class UploadAttachmentParams {
  final int contactId;
  final int? dealId;
  final int? activityId;
  final int attachmentTypeId;
  final String? attachmentNote;
  
  final File? file;
  final Uint8List? fileBytes;
  final String? fileName;
  
  final List<Uint8List>? filesBytesList;
  final List<String>? fileNames;

  UploadAttachmentParams({
    required this.contactId,
    this.dealId,
    this.activityId,
    required this.attachmentTypeId,
    this.attachmentNote,
    this.file,
    this.fileBytes,
    this.fileName,
    this.filesBytesList,
    this.fileNames,
  });
}
