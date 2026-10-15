import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Direct Frontend-to-Database & Resend Mailing Service
///
/// Bypasses backend microservices to directly:
/// 1. Persist waitlist signups into the Supabase database table `waitlist_subscribers`.
/// 2. Dispatch a confirmation email to the subscriber via the Resend API.
class WaitlistService {
  static final WaitlistService _instance = WaitlistService._internal();
  factory WaitlistService() => _instance;
  WaitlistService._internal();

  http.Client? _client;
  set client(http.Client? c) => _client = c;
  http.Client get client => _client ??= http.Client();

  // Supabase Configuration (defaults to EventDock Supabase project)
  static String supabaseUrl = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://grgtlaeinlgbrejymwts.supabase.co',
  );

  static String supabaseAnonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyZ3RsYWVpbmxnYnJlanltd3RzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3MDY5MTksImV4cCI6MjEwNzI4MjkxOX0.t708TVtpPjogbRVM7JpbhWwkliOWop9i5hJn0skRuCc',
  );

  // Resend Mailing API Configuration
  static String resendApiKey = const String.fromEnvironment(
    'RESEND_API_KEY',
    defaultValue: 're_DvwFRoG2_qQ3cEszVg8ieBSqs9L3mNeTv',
  );

  static String resendFromEmail = const String.fromEnvironment(
    'RESEND_FROM_EMAIL',
    defaultValue: 'EventDock <noreply@swynx.dev>',
  );

  /// Allows runtime configuration or overrides if needed
  static void configure({
    String? url,
    String? anonKey,
    String? resendKey,
    String? fromEmail,
  }) {
    if (url != null) supabaseUrl = url;
    if (anonKey != null) supabaseAnonKey = anonKey;
    if (resendKey != null) resendApiKey = resendKey;
    if (fromEmail != null) resendFromEmail = fromEmail;
  }

  // Cache to track emails already confirmed in this session
  static final Set<String> _sessionRegisteredEmails = {};

  /// Main entrypoint: Inserts subscriber to DB directly, then dispatches email via Resend
  Future<Map<String, dynamic>> submitWaitlist({
    required String email,
    String? name,
    String? company,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = (name != null && name.trim().isNotEmpty) ? name.trim() : null;
    final cleanCompany = (company != null && company.trim().isNotEmpty) ? company.trim() : null;

    bool isAlreadyJoined = _sessionRegisteredEmails.contains(cleanEmail);
    String statusMessage = "You're on the waitlist! We will notify you when early access begins.";

    if (isAlreadyJoined) {
      debugPrint('[WaitlistService] $cleanEmail is already in session cache. Skipping Resend dispatch.');
      return {
        'success': true,
        'alreadyJoined': true,
        'message': "You're already a part of the waitlist! We have your early access spot reserved.",
      };
    }

    // 1. Direct Supabase Database Insertion (waitlist_subscribers table)
    if (supabaseAnonKey.isNotEmpty) {
      try {
        final endpoint = Uri.parse('$supabaseUrl/rest/v1/waitlist_subscribers');
        final response = await client.post(
          endpoint,
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode({
            'email': cleanEmail,
            'name': ?cleanName,
            'company': ?cleanCompany,
          }),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _sessionRegisteredEmails.add(cleanEmail);
          debugPrint('[WaitlistService] Successfully inserted $cleanEmail into Supabase.');
        } else if (response.statusCode == 409 ||
            response.body.contains('23505') ||
            response.body.toLowerCase().contains('duplicate')) {
          // Email already exists in the database!
          isAlreadyJoined = true;
          _sessionRegisteredEmails.add(cleanEmail);
          statusMessage = "You're already a part of the waitlist! We have your early access spot reserved.";
          debugPrint('[WaitlistService] $cleanEmail already exists in Supabase. Skipping email dispatch.');
        } else {
          debugPrint('[WaitlistService] Supabase insertion error: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        debugPrint('[WaitlistService] Supabase network exception: $e');
      }
    } else {
      _sessionRegisteredEmails.add(cleanEmail);
    }

    // 2. Dispatch Confirmation Email via Resend API ONLY IF NOT ALREADY JOINED!
    if (!isAlreadyJoined && resendApiKey.isNotEmpty) {
      try {
        await _sendResendConfirmationEmail(
          email: cleanEmail,
          name: cleanName,
        );
      } catch (e) {
        debugPrint('[WaitlistService] Resend email dispatch failed: $e');
      }
    } else if (isAlreadyJoined) {
      debugPrint('[WaitlistService] Skipped Resend email because subscriber is already registered.');
    }

    // 3. Return confirmation status
    if (isAlreadyJoined) {
      statusMessage = "You're already a part of the waitlist! We have your early access spot reserved.";
    } else {
      _sessionRegisteredEmails.add(cleanEmail);
    }

    return {
      'success': true,
      'alreadyJoined': isAlreadyJoined,
      'message': statusMessage,
    };
  }

  /// Sends a branded HTML confirmation email via the Resend REST API
  Future<void> _sendResendConfirmationEmail({
    required String email,
    String? name,
  }) async {
    final displayName = (name != null && name.isNotEmpty) ? name : 'Developer';

    final emailBody = {
      'from': resendFromEmail,
      'to': [email],
      'subject': "You're on the EventDock Waitlist! ⚡",
      'html': '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Welcome to EventDock Early Access</title>
</head>
<body style="margin: 0; padding: 0; background-color: #000000; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #F5F5F5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #000000; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" max-width="560px" cellpadding="0" cellspacing="0" style="max-width: 560px; background-color: #171717; border: 1px solid #383838; border-radius: 12px; padding: 36px 32px; text-align: left;">
          <tr>
            <td>
              <div style="font-size: 26px; font-weight: 800; letter-spacing: -0.5px; margin-bottom: 24px;">
                <span style="color: #F5F5F5;">Event</span><span style="color: #FF7043;">Dock</span>
              </div>
              <h1 style="color: #F5F5F5; font-size: 20px; font-weight: 700; margin: 0 0 14px 0;">
                You're on the early access list, $displayName!
              </h1>
              <p style="color: #A3A3A3; font-size: 14px; line-height: 1.6; margin: 0 0 20px 0;">
                Thank you for signing up. EventDock is a dedicated developer platform designed to detect, inspect, and reproduce API failures in Spring Boot applications.
              </p>
              
              <div style="background-color: #262626; border-left: 3px solid #FF7043; border-radius: 6px; padding: 14px 16px; margin: 20px 0;">
                <div style="color: #F5F5F5; font-size: 13px; font-weight: 600; margin-bottom: 4px;">⚡ What's coming in Early Access:</div>
                <div style="color: #A3A3A3; font-size: 12px; line-height: 1.5;">
                  • <strong>Zero-Latency Error Capture:</strong> Non-blocking 5xx ingestion via eventdock-starter.<br>
                  • <strong>Sanitized Java Traces:</strong> Automatic redaction of sensitive tokens and cookies.<br>
                  • <strong>One-Click Request Replay:</strong> Safe local reproduction with SSRF guardrails.
                </div>
              </div>

              <p style="color: #A3A3A3; font-size: 14px; line-height: 1.6; margin: 0 0 28px 0;">
                We are onboarding teams in batches. We'll send your access credentials directly to this email address.
              </p>

              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td>
                    <a href="https://eventdock.swynx.dev" style="display: inline-block; background-color: #FF7043; color: #000000; font-size: 13px; font-weight: 700; text-decoration: none; padding: 12px 24px; border-radius: 6px;">
                      Visit EventDock →
                    </a>
                  </td>
                </tr>
              </table>

              <hr style="border: none; border-top: 1px solid #383838; margin: 32px 0 20px 0;">
              <p style="color: #666666; font-size: 11px; margin: 0; line-height: 1.4;">
                © 2026 EventDock. Built for Spring Boot microservices. If you didn't request this, you can safely ignore this email.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
'''
    };

    // 1. Try via Vercel serverless proxy to bypass browser CORS restrictions
    try {
      final proxyEndpoint = (Uri.base.host.isNotEmpty && !Uri.base.host.contains('localhost'))
          ? Uri.parse('/api/send')
          : Uri.parse('https://eventdock.swynx.dev/api/send');

      final proxyRes = await client.post(
        proxyEndpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': ?name,
        }),
      );

      if (proxyRes.statusCode >= 200 && proxyRes.statusCode < 300) {
        debugPrint('[WaitlistService] Confirmation email successfully dispatched to $email.');
        return;
      } else {
        debugPrint('[WaitlistService] Proxy dispatch returned: ${proxyRes.statusCode} ${proxyRes.body}');
      }
    } catch (e) {
      debugPrint('[WaitlistService] Proxy send attempt exception: $e');
    }

    // 2. Direct fallback (for non-browser environments or tests)
    final res = await client.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $resendApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(emailBody),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      debugPrint('[WaitlistService] Confirmation email sent to $email via Resend.');
    } else {
      debugPrint('[WaitlistService] Resend API error: ${res.statusCode} ${res.body}');
    }
  }
}
