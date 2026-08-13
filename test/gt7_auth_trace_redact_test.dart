import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/services/gt7_auth_trace.dart';

/// The trace captures bodies from the PSN sign-in flow, so a value that slips
/// through redaction is a real credential in a log the user is asked to paste
/// into a chat. These tests are the guard on that.
void main() {
  group('redact — JSON bodies', () {
    test('masks token fields but keeps numeric expiry readable', () {
      const body =
          '{"is_signed_in":true,"access_token":"eyJhbGciOiJIUzI1NiJ9.payload.sig",'
          '"access_token_expire":1786619347064,"user_id":"038a1147-d5df"}';
      final out = Gt7AuthTrace.redact(body);

      expect(out, isNot(contains('eyJhbGciOiJIUzI1NiJ9.payload.sig')));
      expect(out, contains('"access_token_expire":1786619347064'));
      expect(out, contains('038a1147-d5df'));
    });

    test('masks password, npsso and refresh_token', () {
      const body =
          '{"password":"hunter2-and-then-some","npsso":"2cslF6aaaaaaaaaaaaaaaa",'
          '"refresh_token":"rt_0123456789abcdef"}';
      final out = Gt7AuthTrace.redact(body);

      expect(out, isNot(contains('hunter2-and-then-some')));
      expect(out, isNot(contains('2cslF6aaaaaaaaaaaaaaaa')));
      expect(out, isNot(contains('rt_0123456789abcdef')));
    });
  });

  group('redact — the real PSN credential POST', () {
    // Captured verbatim from POST ca.account.sony.com/api/v1/ssocookie,
    // with the values replaced. The username field is why this test exists:
    // the first version of redact() masked the password and printed the
    // account's email address straight into the log.
    const body =
        '{"authentication_type":"password",'
        '"username":"someone@example.com",'
        '"password":"hunter2!",'
        '"dfp_data":[{"metadata":{"profiling_completed":false},'
        '"session_id":"ffaa5f0011223344556677889900aabbccddeeff0011223344",'
        '"vendor_id":"V001"}],'
        '"client_id":"d5df3976-b7fa-4651-bcc9-05ac9f0cad47"}';

    final out = Gt7AuthTrace.redact(body);

    test('masks the password', () {
      expect(out, isNot(contains('hunter2!')));
    });

    test('masks the account email', () {
      expect(out, isNot(contains('someone@example.com')));
      expect(out, isNot(contains('example.com')));
    });

    test('masks the fingerprinting session id', () {
      expect(out, isNot(contains('ffaa5f0011223344556677889900aabbccddeeff')));
    });

    test('keeps the non-sensitive fields that explain the request', () {
      expect(out, contains('"authentication_type":"password"'));
      expect(out, contains('"profiling_completed":false'));
      expect(out, contains('"vendor_id":"V001"'));
      expect(out, contains('d5df3976-b7fa-4651-bcc9-05ac9f0cad47'));
    });
  });

  group('redact — form-urlencoded bodies', () {
    test('masks both halves of a credential POST', () {
      const body =
          'username=someone%40example.com&password=hunter2-and-then-some'
          '&remember=true';
      final out = Gt7AuthTrace.redact(body);

      expect(out, isNot(contains('hunter2-and-then-some')));
      expect(out, isNot(contains('someone%40example.com')));
      // Non-credential fields still readable, or the log explains nothing.
      expect(out, contains('remember=true'));
    });

    test('masks a secret in the first position, with no leading separator', () {
      final out = Gt7AuthTrace.redact('password=hunter2-and-then-some&x=1');
      expect(out, isNot(contains('hunter2-and-then-some')));
      expect(out, contains('x=1'));
    });

    test('masks secrets carried in a query string', () {
      const url =
          'https://ca.account.sony.com/api/authz/v3/oauth/token'
          '?client_secret=abcdef0123456789&client_id=public-value';
      final out = Gt7AuthTrace.redact(url);

      expect(out, isNot(contains('abcdef0123456789')));
      expect(out, contains('client_id=public-value'));
    });

    test('leaves public PKCE parameters intact', () {
      const url =
          'https://ca.account.sony.com/api/authz/v3/oauth/authorize'
          '?code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM'
          '&code_challenge_method=S256&response_type=code';
      final out = Gt7AuthTrace.redact(url);

      expect(out, contains('E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM'));
      expect(out, contains('code_challenge_method=S256'));
    });

    test('masks code_verifier, which is the secret half of PKCE', () {
      final out = Gt7AuthTrace.redact('code_verifier=super-secret-verifier-x');
      expect(out, isNot(contains('super-secret-verifier-x')));
    });
  });

  group('mask', () {
    test('keeps length visible without revealing the value', () {
      final out = Gt7AuthTrace.mask('abcdefghijklmnopqrstuvwxyz');
      expect(out, contains('len=26'));
      expect(out, isNot(contains('ghijklmnopqrstuv')));
    });

    test('reveals nothing at all for short values', () {
      expect(Gt7AuthTrace.mask('shortpw'), '***(len=7)');
    });

    test('handles null and empty', () {
      expect(Gt7AuthTrace.mask(null), '<null>');
      expect(Gt7AuthTrace.mask(''), '<empty>');
    });
  });
}
