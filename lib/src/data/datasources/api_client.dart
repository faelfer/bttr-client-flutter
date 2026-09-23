import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/app_exception.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.client,
    required this.session,
    this.timeout = const Duration(seconds: 30),
  });
  final Uri baseUrl;
  final http.Client client;
  final SessionStore session;
  final Duration timeout;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool public = false,
  }) async {
    if (!path.startsWith('/') ||
        path.startsWith('//') ||
        path.contains('://')) {
      throw const AppException('Caminho de API inválido.');
    }
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final token = public ? null : session.token;
    final request = http.Request(method, uri)
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Token $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    try {
      final response = await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(timeout);
      if (response.statusCode == 401 &&
          token != null &&
          session.token == token) {
        await session.clear();
      }
      Map<String, dynamic> payload = {};
      if (response.bodyBytes.isNotEmpty) {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic>) payload = decoded;
        } on FormatException {
          /* Fall back to a localized HTTP error below. */
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = payload['message'];
        throw AppException(
          message is String && message.isNotEmpty
              ? message
              : switch (response.statusCode) {
                  401 =>
                    public
                        ? 'E-mail ou senha inválidos.'
                        : 'Sessão encerrada. Entre novamente para continuar.',
                  404 => 'Registro não encontrado.',
                  _ => 'Não foi possível concluir a operação. Tente novamente.',
                },
          statusCode: response.statusCode,
        );
      }
      return payload;
    } on TimeoutException {
      throw const AppException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const AppException(
        'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
      );
    }
  }

  Future<String> message(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool public = false,
  }) async {
    final result = await request(method, path, body: body, public: public);
    return result['message'] as String? ?? 'Operação realizada com sucesso.';
  }

  void close() => client.close();
}
