import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karatly/core/api/auth_api.dart';

class FakeHttpClientAdapter implements HttpClientAdapter {
  final ResponseBody responseBody;

  FakeHttpClientAdapter(this.responseBody);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return responseBody;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('sendOtp does not report success when backend returns a failure payload', () async {
    final dio = Dio();
    dio.httpClientAdapter = FakeHttpClientAdapter(
      ResponseBody.fromString(
        '{"success": false, "message": "OTP not sent"}',
        200,
        headers: {'content-type': ['application/json']},
      ),
    );

    final api = AuthApi(dio);
    final result = await api.sendOtp(mobileNumber: '9999999999', type: 'login');

    expect(result['ok'], isFalse);
    expect(result['success'], isFalse);
    expect(result['message'], 'OTP not sent');
  });
}
