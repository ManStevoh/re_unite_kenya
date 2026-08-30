enum AccountState {
  pendingVerification,
  active,
  restricted,
  suspended,
  banned,
  deactivated,
}

enum VerificationLevel { none, email, phone, idChecked }

enum ReportType { lost, found }

enum ReportStatus {
  draft,
  submitted,
  underReview,
  published,
  matched,
  claimInProgress,
  recovered,
  closed,
  expired,
  rejected,
}

enum Custody { withFinder, atHub, withStaff }

enum Visibility { publicTeaser, privateMatchOnly }

enum ClaimStatus {
  draft,
  submitted,
  moreInfo,
  accepted,
  rejected,
  withdrawn,
  handoverScheduled,
  recovered,
}

enum HandoverType { inPerson, hubPickup, courier }

enum HandoverStatus { scheduled, confirmedOwner, confirmedFinder, completed }

enum NotificationType {
  match,
  claim,
  chat,
  handover,
  system,
}

enum HubType { campus, mall, airport, station, office, municipal }

enum Sensitivity { publicLevel, restricted, highlySensitive }
