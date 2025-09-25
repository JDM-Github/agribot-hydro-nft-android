import 'package:flutter/foundation.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();
  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  void updateConnection(bool value) {
    isConnected.value = value;
  }
}
