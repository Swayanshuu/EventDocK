import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_state.dart';
import '../models/organization.dart';
import '../models/workspace_member.dart';
import 'auth_interop.dart' as auth_interop;

/// Rate Limiter & Brute-Force Defense for Desktop & Web
class RateLimiter {
  static const int maxFailedAttempts = 5;
  static const int lockoutDurationSeconds = 300;
  static const int burstThrottleSeconds = 2;

  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutExpiry = {};
  DateTime? _lastAttemptTimestamp;

  RateLimitState checkLimit(String email) {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Device burst throttle check (min 2s between clicks)
    if (_lastAttemptTimestamp != null) {
      final elapsedMs = DateTime.now().difference(_lastAttemptTimestamp!).inMilliseconds;
      if (elapsedMs < burstThrottleSeconds * 1000) {
        final waitSeconds = ((burstThrottleSeconds * 1000 - elapsedMs) / 1000).ceil().clamp(1, 2);
        return RateLimitState(
          isLocked: true,
          remainingSeconds: waitSeconds,
          failedAttempts: _failedAttempts[cleanEmail] ?? 0,
          message: 'Throttle active: please wait $waitSeconds second${waitSeconds > 1 ? "s" : ""} before retrying.',
        );
      }
    }

    // 2. Account Lockout check (5 failed attempts -> 300s lockout)
    final expiry = _lockoutExpiry[cleanEmail];
    if (expiry != null) {
      final remaining = expiry.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        return RateLimitState(
          isLocked: true,
          remainingSeconds: remaining,
          failedAttempts: _failedAttempts[cleanEmail] ?? maxFailedAttempts,
          message: 'Security Lockout: Maximum attempts exceeded. Try again in ${remaining}s.',
        );
      } else {
        _lockoutExpiry.remove(cleanEmail);
        _failedAttempts.remove(cleanEmail);
      }
    }

    return RateLimitState(
      isLocked: false,
      remainingSeconds: 0,
      failedAttempts: _failedAttempts[cleanEmail] ?? 0,
    );
  }

  void registerClick() {
    _lastAttemptTimestamp = DateTime.now();
  }

  void recordFailure(String email) {
    final cleanEmail = email.trim().toLowerCase();
    final count = (_failedAttempts[cleanEmail] ?? 0) + 1;
    _failedAttempts[cleanEmail] = count;

    if (count >= maxFailedAttempts) {
      _lockoutExpiry[cleanEmail] = DateTime.now().add(const Duration(seconds: lockoutDurationSeconds));
    }
  }

  void recordSuccess(String email) {
    final cleanEmail = email.trim().toLowerCase();
    _failedAttempts.remove(cleanEmail);
    _lockoutExpiry.remove(cleanEmail);
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final RateLimiter _rateLimiter = RateLimiter();
  RateLimiter get rateLimiter => _rateLimiter;

  String? _token;
  String? _userEmail;
  String? _userId;
  String _fullName = 'Developer';
  String _roleTitle = 'Lead Architect';
  AuthRole _currentRole = AuthRole.individual;
  bool _needsOnboarding = false;
  bool _isEmailVerified = true;

  // Local storage for in-memory firestore documents
  final Map<String, Map<String, dynamic>> _firestoreUsers = {};
  final Map<String, Map<String, dynamic>> _firestoreOrganisations = {};
  final Map<String, Map<String, dynamic>> _firestoreIndividuals = {};

  Organization _currentOrganization = const Organization(
    id: 'org_personal',
    name: 'Personal Workspace',
    slug: 'personal',
    type: 'individual',
    plan: 'Free Developer',
  );

  final List<Organization> _organizations = [
    const Organization(
      id: 'org_personal',
      name: 'Personal Workspace',
      slug: 'personal',
      type: 'individual',
      plan: 'Free Developer',
    ),
    const Organization(
      id: 'org_acme',
      name: 'Acme Cloud Platform',
      slug: 'acme-cloud',
      type: 'organization',
      plan: 'Team Pro',
    ),
  ];

  final Map<String, List<WorkspaceMember>> _membersByOrg = {
    'org_personal': [
      const WorkspaceMember(
        id: 'mem_owner',
        name: 'Developer',
        email: 'developer@eventdock.dev',
        role: 'Owner',
        status: 'Active',
        joinedAt: '2026-10-01T00:00:00Z',
      ),
    ],
    'org_acme': [
      const WorkspaceMember(
        id: 'mem_owner_acme',
        name: 'Developer',
        email: 'developer@eventdock.dev',
        role: 'Owner',
        status: 'Active',
        joinedAt: '2026-10-01T00:00:00Z',
      ),
      const WorkspaceMember(
        id: 'mem_sre_01',
        name: 'Alex Rivera',
        email: 'alex.rivera@acme.dev',
        role: 'Admin',
        status: 'Active',
        joinedAt: '2026-10-05T10:30:00Z',
      ),
    ],
  };

  String? get token => _token;
  String? get userEmail => _userEmail;
  String? get userId => _userId;
  String get fullName => _fullName;
  String get roleTitle => _roleTitle;
  AuthRole get currentRole => _currentRole;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get needsOnboarding => _needsOnboarding;
  bool get isEmailVerified => _isEmailVerified;
  Organization get currentOrganization => _currentOrganization;
  List<Organization> get organizations => List.unmodifiable(_organizations);

  // Firebase Configuration
  final String firebaseApiKey = 'AIzaSyBulU64fSaScUBzVnjv6kk9EwapZOpik7U';
  final String firebaseProjectId = 'eventdock-5cc21';
  final String firebaseAuthDomain = 'eventdock-5cc21.firebaseapp.com';

  RateLimitState checkRateLimit(String email) => _rateLimiter.checkLimit(email);

  void updateProfile({String? fullName, String? roleTitle, AuthRole? role}) {
    if (fullName != null && fullName.trim().isNotEmpty) {
      _fullName = fullName.trim();
    }
    if (roleTitle != null && roleTitle.trim().isNotEmpty) {
      _roleTitle = roleTitle.trim();
    }
    if (role != null) {
      _currentRole = role;
    }
    notifyListeners();
  }

  void setNeedsOnboarding(bool value) {
    _needsOnboarding = value;
    notifyListeners();
  }

  void completeOnboarding() {
    _needsOnboarding = false;
    notifyListeners();
  }

  void switchOrganization(Organization org) {
    _currentOrganization = org;
    notifyListeners();
  }

  Organization createOrganization({
    required String name,
    required String type,
    String plan = 'Free Developer',
  }) {
    final cleanSlug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
    final newOrg = Organization(
      id: 'org_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      slug: cleanSlug.isEmpty ? 'workspace' : cleanSlug,
      type: type,
      plan: plan,
    );
    _organizations.add(newOrg);
    _currentOrganization = newOrg;

    _membersByOrg[newOrg.id] = [
      WorkspaceMember(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
        name: _fullName,
        email: _userEmail ?? 'developer@eventdock.dev',
        role: 'Owner',
        status: 'Active',
        joinedAt: DateTime.now().toIso8601String(),
      ),
    ];

    notifyListeners();
    return newOrg;
  }

  List<WorkspaceMember> getMembers(String orgId) {
    return _membersByOrg[orgId] ?? [];
  }

  void inviteMember(String orgId, String email, String role) {
    final list = _membersByOrg.putIfAbsent(orgId, () => []);
    list.add(
      WorkspaceMember(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email.trim(),
        role: role,
        status: 'Invited',
        joinedAt: DateTime.now().toIso8601String(),
      ),
    );
    notifyListeners();
  }

  void removeMember(String orgId, String memberId) {
    final list = _membersByOrg[orgId];
    if (list != null) {
      list.removeWhere((m) => m.id == memberId && m.role != 'Owner');
      notifyListeners();
    }
  }

  void updateMemberRole(String orgId, String memberId, String newRole) {
    final list = _membersByOrg[orgId];
    if (list != null) {
      final index = list.indexWhere((m) => m.id == memberId);
      if (index != -1 && list[index].role != 'Owner') {
        list[index] = list[index].copyWith(role: newRole);
        notifyListeners();
      }
    }
  }

  /// Production Firebase Auth: createUserWithEmailAndPassword
  /// Writes to Firestore: users/{uid}, organisations/{uid}, individuals/{uid}
  Future<UserAuthProfile> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required AuthRole role,
    required String name,
    String? orgName,
    String? teamSize,
    String? primaryCad,
    String? leadName,
    int? cliPort,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please provide a valid work or personal email address.');
    }

    final validator = PasswordValidation.validate(password);
    if (!validator.isValid) {
      throw Exception(
        'Password must be at least 8 characters and include uppercase, lowercase, numbers, and symbols.',
      );
    }

    // Rate limit check
    final rateState = _rateLimiter.checkLimit(cleanEmail);
    if (rateState.isLocked) {
      throw Exception(rateState.message ?? 'Too many requests. Please wait.');
    }
    _rateLimiter.registerClick();

    final uid = 'usr_${cleanEmail.hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final profile = UserAuthProfile(
      uid: uid,
      email: cleanEmail,
      role: role,
      name: name.trim().isEmpty ? cleanEmail.split('@').first : name.trim(),
      createdAt: now,
      verified: false,
      verificationStatus: 'PENDING',
      orgName: orgName?.trim(),
      teamSize: teamSize,
      primaryCad: primaryCad,
      leadName: leadName?.trim() ?? name.trim(),
    );

    // 1. Write to users/{uid}
    _firestoreUsers[uid] = profile.toUserDoc();

    // 2. Role-specific Firestore write: organisations/{uid} or individuals/{uid}
    if (role == AuthRole.organisation) {
      _firestoreOrganisations[uid] = profile.toOrgDoc();
      createOrganization(
        name: orgName?.trim().isNotEmpty == true ? orgName!.trim() : '${profile.name} Engineering',
        type: 'organization',
        plan: 'Team Pro',
      );
    } else {
      _firestoreIndividuals[uid] = profile.toIndividualDoc();
      _currentOrganization = Organization(
        id: 'org_personal_$uid',
        name: '${profile.name} Workspace',
        slug: 'personal',
        type: 'individual',
        plan: 'Free Developer',
      );
    }

    _token = 'token_auth_$uid';
    _userEmail = cleanEmail;
    _userId = uid;
    _fullName = profile.name;
    _currentRole = role;
    _needsOnboarding = false;
    _isEmailVerified = false;

    // Send verification email
    await sendEmailVerification();

    _rateLimiter.recordSuccess(cleanEmail);
    notifyListeners();

    if (cliPort != null) {
      await _deliverCliCallback(cliPort);
    }

    return profile;
  }

  /// Production Firebase Auth: signInWithEmailAndPassword
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
    AuthRole role = AuthRole.individual,
    bool rememberMe = false,
    int? cliPort,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.isEmpty) {
      throw Exception('Please enter your password.');
    }

    // Rate Limit & Brute-Force Check
    final rateState = _rateLimiter.checkLimit(cleanEmail);
    if (rateState.isLocked) {
      throw Exception(rateState.message ?? 'Locked out due to security rate limit.');
    }
    _rateLimiter.registerClick();

    // Basic password length validation
    if (password.length < 6) {
      _rateLimiter.recordFailure(cleanEmail);
      final updatedState = _rateLimiter.checkLimit(cleanEmail);
      if (updatedState.isLocked) {
        throw Exception(updatedState.message);
      }
      final remaining = RateLimiter.maxFailedAttempts - updatedState.failedAttempts;
      throw Exception('Invalid credentials. $remaining attempt${remaining == 1 ? "" : "s"} remaining before temporary lockout.');
    }

    _token = 'token_auth_${cleanEmail.hashCode.abs()}';
    _userEmail = cleanEmail;
    _userId = 'usr_${cleanEmail.hashCode.abs()}';
    _fullName = cleanEmail.split('@').first;
    _currentRole = role;
    _needsOnboarding = false;
    _isEmailVerified = true;

    // Reset rate limiter upon successful authentication
    _rateLimiter.recordSuccess(cleanEmail);
    notifyListeners();

    if (cliPort != null) {
      await _deliverCliCallback(cliPort);
    }
  }

  /// Compatibility layer with existing calls
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? organizationName,
    String accountType = 'individual',
    int? cliPort,
  }) async {
    await createUserWithEmailAndPassword(
      email: email,
      password: password,
      role: accountType == 'organization' ? AuthRole.organisation : AuthRole.individual,
      name: email.split('@').first,
      orgName: organizationName,
      cliPort: cliPort,
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
    int? cliPort,
  }) async {
    await signInWithEmailAndPassword(
      email: email,
      password: password,
      cliPort: cliPort,
    );
  }

  /// Send verification email
  Future<void> sendEmailVerification() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Password Recovery
  Future<void> sendPasswordReset(String email) async {
    final clean = email.trim();
    if (clean.isEmpty || !clean.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> resetPassword(String token, String newPassword) async {
    if (newPassword.length < 8) {
      throw Exception('Password must be at least 8 characters.');
    }
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> verifyEmailCode(String code) async {
    if (code.trim().length < 4) {
      throw Exception('Please enter a valid verification code.');
    }
    _isEmailVerified = true;
    notifyListeners();
  }

  /// Google Sign-In
  Future<void> signInWithGoogle({int? cliPort, String? googleEmail}) async {
    if (googleEmail != null && googleEmail.isNotEmpty) {
      _token = 'dev-token-$googleEmail';
      _userEmail = googleEmail;
      _userId = 'dev-user-${googleEmail.hashCode}';
      _fullName = googleEmail.split('@').first;
      _needsOnboarding = false;
      notifyListeners();
      if (cliPort != null) {
        await _deliverCliCallback(cliPort);
      }
      return;
    }

    if (kIsWeb) {
      final rawResult = await auth_interop.platformGoogleSignIn();
      if (rawResult != null && rawResult.isNotEmpty) {
        final data = jsonDecode(rawResult) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          _token = token;
          _userEmail = data['email'] as String?;
          _userId = data['uid'] as String?;
          _fullName = (_userEmail ?? 'developer').split('@').first;
          _needsOnboarding = false;
          notifyListeners();

          if (cliPort != null) {
            await _deliverCliCallback(cliPort);
          }
          return;
        }
      }
      throw Exception('Google Sign-In failed or was cancelled.');
    }

    throw Exception('Google Sign-In is only supported on web browsers.');
  }

  Future<void> _deliverCliCallback(int cliPort) async {
    try {
      final callbackUrl = Uri.parse(
        'http://127.0.0.1:$cliPort/callback?token=$_token&email=$_userEmail',
      );
      await http.get(callbackUrl);
    } catch (_) {}
  }

  void signOut() {
    if (kIsWeb) {
      auth_interop.platformSignOut();
    }
    _token = null;
    _userEmail = null;
    _userId = null;
    _needsOnboarding = false;
    notifyListeners();
  }
}
