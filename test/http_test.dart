import 'dart:async';

import 'package:checks/checks.dart';
import 'package:http/http.dart';
import 'package:puro/src/http.dart';
import 'package:test/test.dart';

void main() {
  group('HttpException', () {
    test('constructs with status code and body', () {
      const exc = HttpException(statusCode: 404, body: 'Not found');
      check(exc.statusCode).equals(404);
      check(exc.body).equals('Not found');
      check(exc.uri).isNull();
    });

    test('constructs with URI', () {
      final uri = Uri.parse('https://example.com');
      final exc = HttpException(uri: uri, statusCode: 500, body: 'error');
      check(exc.uri).equals(uri);
    });

    test('fromResponse extracts fields from Response', () {
      final resp = Response(
        '{"error":"bad"}',
        400,
        request: Request('GET', Uri.parse('https://example.com/api')),
      );
      final exc = HttpException.fromResponse(resp);
      check(exc.statusCode).equals(400);
      check(exc.body).equals('{"error":"bad"}');
      check(exc.uri).equals(Uri.parse('https://example.com/api'));
    });

    test('fromResponse sets body to null for StreamedResponse', () {
      final resp = StreamedResponse(
        const Stream.empty(),
        502,
        request: Request('GET', Uri.parse('https://example.com')),
      );
      final exc = HttpException.fromResponse(resp);
      check(exc.statusCode).equals(502);
      check(exc.body).isNull();
    });

    test('fromResponse handles null request', () {
      final resp = Response('body', 500);
      final exc = HttpException.fromResponse(resp);
      check(exc.uri).isNull();
    });

    test('ensureSuccess does not throw for 2xx', () {
      final resp = Response('ok', 200);
      HttpException.ensureSuccess(resp);
    });

    test('ensureSuccess throws for non-2xx', () {
      final resp = Response('bad', 400, request: Request('GET', Uri.parse('https://example.com')));
      check(() => HttpException.ensureSuccess(resp)).throws<HttpException>();
    });

    test('toString includes status code', () {
      const exc = HttpException(statusCode: 404, body: 'Not found');
      check(exc.toString()).contains('404');
    });

    test('toString includes URI when present', () {
      final exc = HttpException(
        uri: Uri.parse('https://example.com'),
        statusCode: 500,
        body: 'error',
      );
      check(exc.toString()).contains('https://example.com');
    });

    test('toString prettifies JSON body', () {
      const exc = HttpException(statusCode: 400, body: '{"error":"bad"}');
      final str = exc.toString();
      check(str).contains('"error"');
      check(str).contains('"bad"');
    });

    test('toString handles non-JSON body', () {
      const exc = HttpException(statusCode: 500, body: 'plain text');
      check(exc.toString()).contains('plain text');
    });
  });

  group('UriExtensions.append', () {
    test('appends path segment', () {
      final uri = Uri.parse('https://example.com/api').append(path: 'v1');
      check(uri.toString()).equals('https://example.com/api/v1');
    });

    test('appends multiple path segments', () {
      final uri = Uri.parse('https://example.com').append(path: 'a/b/c');
      check(uri.toString()).equals('https://example.com/a/b/c');
    });

    test('empty string path preserves path with trailing slash', () {
      final uri = Uri.parse('https://example.com/api').append();
      check(uri.path).equals('/api/');
    });

    test('adds query parameters', () {
      final uri = Uri.parse(
        'https://example.com',
      ).append(path: 'api', queryParameters: {'key': 'value'});
      check(uri.toString()).equals('https://example.com/api?key=value');
    });

    test('converts int query values to strings', () {
      final uri = Uri.parse(
        'https://example.com',
      ).append(path: 'api', queryParameters: {'num': 42});
      check(uri.toString()).equals('https://example.com/api?num=42');
    });

    test('converts iterable query values', () {
      final uri = Uri.parse('https://example.com').append(
        path: 'api',
        queryParameters: {
          'list': ['a', 'b'],
        },
      );
      check(uri.toString()).contains('list=a');
      check(uri.toString()).contains('list=b');
    });

    test('adds fragment', () {
      final uri = Uri.parse('https://example.com/api').append(fragment: 'section');
      check(uri.fragment).equals('section');
    });

    test('preserves scheme', () {
      final uri = Uri.parse('http://example.com').append(path: 'foo');
      check(uri.scheme).equals('http');
    });

    test('preserves port', () {
      final uri = Uri.parse('https://example.com:8080').append(path: 'foo');
      check(uri.port).equals(8080);
    });

    test('preserves user info', () {
      final uri = Uri.parse('https://user:pass@example.com').append(path: 'foo');
      check(uri.userInfo).equals('user:pass');
    });
  });

  group('BaseRequestExtensions.copyWith', () {
    test('copies with new body', () async {
      final original = StreamedRequest('POST', Uri.parse('https://example.com'));
      original.sink.add([1, 2, 3]);
      unawaited(original.sink.close());
      final copy = original.copyWith(headers: {'X-Custom': 'value'});
      check(copy.method).equals('POST');
      check(copy.url.toString()).equals('https://example.com');
      check(copy.headers['x-custom']).equals('value');
    });

    test('copyWith can override extraHeaders', () {
      final original = StreamedRequest('GET', Uri.parse('https://example.com'));
      final copy = original.copyWith(extraHeaders: {'Authorization': 'Bearer xyz'});
      check(copy.headers['authorization']).equals('Bearer xyz');
    });

    test('followRedirects is preserved', () {
      final original = StreamedRequest('GET', Uri.parse('https://example.com'))
        ..followRedirects = false;
      final copy = original.copyWith();
      check(copy.followRedirects).isFalse();
    });
  });
}
