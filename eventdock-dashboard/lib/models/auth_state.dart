enum AuthRole {
  individual,
  organisation,
}

enum AuthMode {
  signIn,
  signUp,
  forgotPassword,
}

class PasswordValidation {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordValidation({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  factory PasswordValidation.validate(String password) {
    return PasswordValidation(
      hasMinLength: password.length >= 8,
      hasUppercase: password.contains(RegExp(r'[A-Z]')),
      hasLowercase: password.contains(RegExp(r'[a-z]')),
      hasDigit: password.contains(RegExp(r'[0-9]')),
      hasSpecialChar: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    );
  }

  bool get isValid =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigit &&
      hasSpecialChar;

  double get strengthScore {
    double score = 0.0;
    if (hasMinLength) score += 0.2;
    if (hasUppercase) score += 0.2;
    if (hasLowercase) score += 0.2;
    if (hasDigit) score += 0.2;
    if (hasSpecialChar) score += 0.2;
    return score;
  }
}

class RateLimitState {
  final bool isLocked;
  final int remainingSeconds;
  final int failedAttempts;
  final String? message;

  const RateLimitState({
    this.isLocked = false,
    this.remainingSeconds = 0,
    this.failedAttempts = 0,
    this.message,
  });

  RateLimitState copyWith({
    bool? isLocked,
    int? remainingSeconds,
    int? failedAttempts,
    String? message,
  }) {
    return RateLimitState(
      isLocked: isLocked ?? this.isLocked,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      message: message ?? this.message,
    );
  }
}

class UserAuthProfile {
  final String uid;
  final String email;
  final AuthRole role;
  final String name;
  final DateTime createdAt;
  final bool verified;
  final String verificationStatus;
  final String? orgName;
  final String? teamSize;
  final String? primaryCad;
  final String? leadName;

  const UserAuthProfile({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    required this.createdAt,
    this.verified = false,
    this.verificationStatus = 'PENDING',
    this.orgName,
    this.teamSize,
    this.primaryCad,
    this.leadName,
  });

  Map<String, dynamic> toUserDoc() {
    return {
      'uid': uid,
      'email': email,
      'role': role == AuthRole.organisation ? 'organisation' : 'individual',
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'verified': verified,
      'verificationStatus': verificationStatus,
    };
  }

  Map<String, dynamic> toOrgDoc() {
    return {
      'orgName': orgName ?? name,
      'teamSize': teamSize ?? '1-10',
      'primaryCad': primaryCad ?? 'AutoCAD / SolidWorks',
      'leadName': leadName ?? name,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toIndividualDoc() {
    return {
      'name': name,
      'primaryCad': primaryCad ?? 'AutoCAD',
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}
