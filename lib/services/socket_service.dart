import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

enum ServerStatus { Online, Offline, Connecting }

// ChangeNotifier Help to comunnicate with the provider when is neccessary to refresh the UI when a changue are ocurred
class SocketService with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.Connecting;
  late Socket _socket;
  Socket get socket => _socket;

  Function get emit => socket.emit;

  ServerStatus get serverStatus => _serverStatus;

  SocketService() {
    _initConfig();
  }

  void _initConfig() {
    // Dart client
    _socket = io(
        'http://localhost:3001',
        OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .enableAutoConnect()
            .build());
    _socket.onConnect((_) {
      _serverStatus = ServerStatus.Online;
      notifyListeners();
    });
    _socket.onDisconnect((_) {
      _serverStatus = ServerStatus.Offline;
      notifyListeners();
    });
    _socket.on('nuevo-mensaje', (payload) => {print('nuevo-mensaje $payload')});
  }
}
