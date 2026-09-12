class DriverOnboardingModel {
  final String status;
  final bool payoutLocked;
  final bool externalVerificationConsent;
  final bool canWork;
  final String? documentsDueAt;
  final int? daysRemaining;
  final List<DriverDocumentModel> documents;

  const DriverOnboardingModel({
    required this.status,
    required this.payoutLocked,
    required this.externalVerificationConsent,
    required this.canWork,
    required this.documents,
    this.documentsDueAt,
    this.daysRemaining,
  });

  factory DriverOnboardingModel.fromJson(Map<String, dynamic> json) {
    return DriverOnboardingModel(
      status: json['status']?.toString() ?? 'documents_pending',
      payoutLocked: json['payout_locked'] == true,
      externalVerificationConsent:
          json['external_verification_consent'] == true,
      canWork: json['can_work'] == true,
      documentsDueAt: json['documents_due_at']?.toString(),
      daysRemaining: json['days_remaining'] is num
          ? (json['days_remaining'] as num).toInt()
          : null,
      documents: (json['documents'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DriverDocumentModel.fromJson)
          .toList(),
    );
  }
}

class DriverDocumentModel {
  final String type;
  final String label;
  final String status;
  final bool uploaded;
  final bool requiredForWork;
  final bool requiredForPayout;
  final String? rejectionReason;

  const DriverDocumentModel({
    required this.type,
    required this.label,
    required this.status,
    required this.uploaded,
    required this.requiredForWork,
    required this.requiredForPayout,
    this.rejectionReason,
  });

  factory DriverDocumentModel.fromJson(Map<String, dynamic> json) {
    return DriverDocumentModel(
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      status: json['status']?.toString() ?? 'missing',
      uploaded: json['uploaded'] == true,
      requiredForWork: json['required_for_work'] == true,
      requiredForPayout: json['required_for_payout'] == true,
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}
