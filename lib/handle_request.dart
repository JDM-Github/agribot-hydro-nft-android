import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestHandler {

  static bool useLiveUrl = false; 
  String get baseUrl {
    return RequestHandler.useLiveUrl
        ? 'https://agribot-hydro-nft-admin.netlify.app'
        : 'https://agribot-subdomain--agribot-hydro-nft-admin.netlify.live';
  }

  Future<Map<String, dynamic>> handleRequest(
    String endpoint, {
    String method = 'POST',
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/.netlify/functions/api/$endpoint');
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(
            url,
            headers: headers ?? {'Content-Type': 'application/json'},
          );
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers ?? {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers ?? {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(
            url,
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        return responseData;
      } else if (responseData['success'] == false) {
        return {'success': false, 'message': responseData['message'] ?? "Invalid request."};
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      return {'success': false, 'message': 'Request failed: $e'};
    }
  }

  Future<List<dynamic>> customFetch(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    String? token,
    bool isMultipart = false,
  }) async {
    final url = Uri.parse('https://agribot-pi4.tail13df43.ts.net:8000/$endpoint');

    try {
      http.Response response;

      if (isMultipart && body != null && body.containsKey('file')) {
        final request = http.MultipartRequest(method.toUpperCase(), url);

        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        final fileBytes = body['file'] as List<int>;
        final fileName = body['fileName'] ?? 'upload.jpg';
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );

        body.forEach((key, value) {
          if (key != 'file' && key != 'fileName') {
            request.fields[key] = value.toString();
          }
        });

        final streamed = await request.send();
        response = await http.Response.fromStream(streamed);
      } else {
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (token != null) headers['Authorization'] = 'Bearer $token';

        final encodedBody = (body != null && method.toUpperCase() != 'GET') ? jsonEncode(body) : null;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(url, headers: headers);
            break;
          case 'POST':
            response = await http.post(url, headers: headers, body: encodedBody);
            break;
          case 'PUT':
            response = await http.put(url, headers: headers, body: encodedBody);
            break;
          case 'DELETE':
            response = await http.delete(url, headers: headers, body: encodedBody);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }
      }

      final data = jsonDecode(response.body);
      return [response.statusCode >= 200 && response.statusCode < 300, data];
    } catch (e) {
      return [
        false,
        {'error': e.toString()}
      ];
    }
  }

  Future<List<dynamic>> authFetch(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    String token = 'agribot-pi4',
    bool isMultipart = false
  }) async {
    return customFetch(endpoint, method: method, body: body, token: token, isMultipart: isMultipart);
  }
  Future<List<dynamic>> normalFetch(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool isMultipart = false
  }) async {
    return customFetch(endpoint, method: method, body: body, token: null, isMultipart: isMultipart);
  }
}
