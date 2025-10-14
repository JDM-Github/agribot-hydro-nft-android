import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static void init([String url = 'https://agribot-pi4.tail13df43.ts.net:8000']) {
    if (_socket != null) return;

    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
  }

  static IO.Socket? get socket => _socket;

  static void connect() {
    if (_socket == null) return;
    if (!_socket!.connected) _socket!.connect();
  }

  static void disconnect() {
    if (_socket != null && _socket!.connected) _socket!.disconnect();
  }

  static void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  static void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  static bool get isConnected => _socket?.connected ?? false;

  static String? get id => _socket?.id;
}
