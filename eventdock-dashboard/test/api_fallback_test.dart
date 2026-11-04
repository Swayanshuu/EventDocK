import 'package:flutter_test/flutter_test.dart';
import 'package:eventdock_dashboard/services/api_service.dart';

void main() {
  group('ApiService Localhost Fallback Engine Tests', () {
    final api = ApiService();

    setUp(() {
      api.resetBaseUrl();
    });

    tearDown(() {
      api.resetBaseUrl();
    });

    test('Candidate URLs contains domain URL followed by localhost:8080 and 127.0.0.1:8080', () {
      final candidates = api.candidateUrls;
      expect(candidates.isNotEmpty, isTrue);
      expect(candidates.contains('http://localhost:8080/api/v1'), isTrue);
      expect(candidates.contains('http://127.0.0.1:8080/api/v1'), isTrue);
      expect(candidates.first, equals('https://api.eventdock.swynx.dev/api/v1'));
    });

    test('Default baseUrl points to production domain', () {
      expect(api.baseUrl, equals('https://api.eventdock.swynx.dev/api/v1'));
      expect(api.isUsingLocalhost, isFalse);
    });

    test('Setting baseUrl to localhost:8080 activates isUsingLocalhost', () {
      api.setBaseUrl('http://localhost:8080/api/v1');
      expect(api.baseUrl, equals('http://localhost:8080/api/v1'));
      expect(api.isUsingLocalhost, isTrue);
    });

    test('Setting baseUrl to 127.0.0.1:8080 activates isUsingLocalhost', () {
      api.setBaseUrl('http://127.0.0.1:8080/api/v1');
      expect(api.baseUrl, equals('http://127.0.0.1:8080/api/v1'));
      expect(api.isUsingLocalhost, isTrue);
    });

    test('resetBaseUrl restores default domain URL', () {
      api.setBaseUrl('http://localhost:8080/api/v1');
      expect(api.isUsingLocalhost, isTrue);
      api.resetBaseUrl();
      expect(api.baseUrl, equals('https://api.eventdock.swynx.dev/api/v1'));
      expect(api.isUsingLocalhost, isFalse);
    });
  });
}

