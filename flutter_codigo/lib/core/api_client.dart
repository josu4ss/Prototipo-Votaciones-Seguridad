import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'session_store.dart';
import '../models/election.dart';

// Emulador Android: 10.0.2.2 corresponde a localhost del equipo anfitrión.
// Para teléfono físico, sustituir por IP LAN y usar HTTPS en despliegue real.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api',
);

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ApiClient {
  final SessionStore session;
  final http.Client _http;
  ApiClient(this.session) : _http = http.Client();

  Future<Map<String, dynamic>> _request(String method, String path, {Object? body, bool authenticated = true}) async {
    final token = authenticated ? await session.token : null;
    final uri = Uri.parse('$apiBaseUrl$path');
    try {
      final request = http.Request(method, uri);
      request.headers['Content-Type'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _http.send(request).timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamed);
      final dynamic decoded = response.body.isEmpty ? <String,dynamic>{} : jsonDecode(response.body);
      final data = decoded is Map<String,dynamic> ? decoded : <String,dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final raw = data['message'];
        final detail = raw is List ? raw.join(', ') : (raw?.toString() ?? 'Error de comunicación');
        throw ApiException(detail, response.statusCode);
      }
      return data;
    } on ApiException { rethrow; }
      on TimeoutException { throw ApiException('El servidor no respondió a tiempo.'); }
      on FormatException { throw ApiException('El servidor respondió con un formato inválido.'); }
      catch (_) { throw ApiException('Sin conexión con la API. Revisa Docker y NestJS.'); }
  }

  Future<String> login(String email, String password) async {
    final r = await _request('POST', '/auth/login', authenticated:false, body:{'email':email.trim(),'password':password});
    final token = r['accessToken'] as String;
    final user = r['user'] as Map<String,dynamic>;
    final role = user['role'] as String;
    await session.save(token:token,role:role);
    return role;
  }

  Future<ElectionData> election() async => ElectionData.fromJson(await _request('GET','/election'));
  Future<String> vote(String candidateId) async {
    final r=await _request('POST','/votes',body:{'candidateId':candidateId});
    return r['receipt'] as String;
  }
  Future<ResultsData> results() async => ResultsData.fromJson(await _request('GET','/election/results'));
  Future<void> close() async {
    await _request('POST','/election/close');
  }
  Future<Map<String,dynamic>> myParticipation() => _request('GET','/votes/me');
  void dispose() => _http.close();
}
