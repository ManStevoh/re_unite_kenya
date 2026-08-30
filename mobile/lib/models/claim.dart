import 'enums.dart';

class MatchCandidate {
  const MatchCandidate({
    required this.id,
    required this.myReportId,
    required this.otherReportId,
    required this.score,
    required this.reasons,
    this.otherTitle,
    this.otherThumbnail,
    this.otherArea,
    this.otherType = ReportType.found,
    this.otherCategory,
  });

  final String id;
  final String myReportId;
  final String otherReportId;
  final int score;
  final List<String> reasons;
  final String? otherTitle;
  final String? otherThumbnail;
  final String? otherArea;
  final ReportType otherType;
  final String? otherCategory;
}

class ChallengeQuestion {
  const ChallengeQuestion({
    required this.id,
    required this.prompt,
    this.hint,
  });

  final String id;
  final String prompt;
  final String? hint;
}

class Claim {
  const Claim({
    required this.id,
    required this.reportId,
    required this.claimantId,
    required this.status,
    this.reportTitle,
    this.answers = const {},
    this.evidence = const [],
    this.timeline = const [],
    this.moreInfoRequest,
    this.createdAt,
    this.attempt = 1,
  });

  final String id;
  final String reportId;
  final String claimantId;
  final ClaimStatus status;
  final String? reportTitle;
  final Map<String, String> answers;
  final List<String> evidence;
  final List<ClaimEvent> timeline;
  final String? moreInfoRequest;
  final DateTime? createdAt;
  final int attempt;

  String get statusLabel {
    switch (status) {
      case ClaimStatus.draft:
        return 'Draft';
      case ClaimStatus.submitted:
        return 'Awaiting review';
      case ClaimStatus.moreInfo:
        return 'More info requested';
      case ClaimStatus.accepted:
        return 'Accepted';
      case ClaimStatus.rejected:
        return 'Not verified';
      case ClaimStatus.withdrawn:
        return 'Withdrawn';
      case ClaimStatus.handoverScheduled:
        return 'Handover scheduled';
      case ClaimStatus.recovered:
        return 'Recovered';
    }
  }

  Claim copyWith({
    ClaimStatus? status,
    Map<String, String>? answers,
    List<String>? evidence,
    List<ClaimEvent>? timeline,
    String? moreInfoRequest,
  }) {
    return Claim(
      id: id,
      reportId: reportId,
      claimantId: claimantId,
      status: status ?? this.status,
      reportTitle: reportTitle,
      answers: answers ?? this.answers,
      evidence: evidence ?? this.evidence,
      timeline: timeline ?? this.timeline,
      moreInfoRequest: moreInfoRequest ?? this.moreInfoRequest,
      createdAt: createdAt,
      attempt: attempt,
    );
  }
}

class ClaimEvent {
  const ClaimEvent({required this.label, required this.at, this.detail});

  final String label;
  final DateTime at;
  final String? detail;
}

class Handover {
  const Handover({
    required this.id,
    required this.claimId,
    required this.type,
    required this.status,
    this.place,
    this.when,
    this.code,
    this.ownerConfirmed = false,
    this.finderConfirmed = false,
  });

  final String id;
  final String claimId;
  final HandoverType type;
  final HandoverStatus status;
  final String? place;
  final DateTime? when;
  final String? code;
  final bool ownerConfirmed;
  final bool finderConfirmed;

  Handover copyWith({
    HandoverStatus? status,
    bool? ownerConfirmed,
    bool? finderConfirmed,
  }) {
    return Handover(
      id: id,
      claimId: claimId,
      type: type,
      status: status ?? this.status,
      place: place,
      when: when,
      code: code,
      ownerConfirmed: ownerConfirmed ?? this.ownerConfirmed,
      finderConfirmed: finderConfirmed ?? this.finderConfirmed,
    );
  }
}
