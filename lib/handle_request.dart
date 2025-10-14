import 'package:http/http.dart' as http;
import 'dart:convert';

// RESTAPI
class RequestHandler {
  final bool development;
  RequestHandler({this.development = true});

  String get baseUrl {
    String dev = 'https://c204d49e--agribot-hydro-nft-admin.netlify.live';
    // return development ? 'http://localhost:8888' : 'https://agribot-hydro-nft-admin.netlify.app';
    return dev;
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
}
