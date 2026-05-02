enum FormStatus { draft, saved, finalized, voided }

class ObluForm {
  final String formNo;
  final DateTime dateCreated;
  final DateTime dateNeeded;
  final FormStatus status;
  final String? details;
  final String? timeIn;
  final String? timeOut;
  final String? reason;
  final String? attachmentPath;
  final String? lateReason;
  final String type;

  ObluForm({
    required this.formNo,
    required this.dateCreated,
    required this.dateNeeded,
    this.status = FormStatus.draft,
    this.details,
    this.timeIn,
    this.timeOut,
    this.reason,
    this.attachmentPath,
    this.lateReason,
    required this.type,
  });
}
