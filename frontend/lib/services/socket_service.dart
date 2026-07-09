import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  io.Socket? _socket;

  // Callbacks
  Function(Map<String, dynamic>)? onReminderUpdated;
  Function(Map<String, dynamic>)? onReminderCreated;
  Function(int)? onReminderDeleted;
  Function()? onLogsUpdated;
  Function()? onTeamUpdate;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String baseUrl) {
    // Disconnect existing socket if any
    disconnect();

    // Derive WebSocket server root URL (e.g. http://10.0.2.2:3000/api -> http://10.0.2.2:3000)
    String socketUrl = baseUrl.replaceAll('/api', '');
    if (socketUrl.endsWith('/')) {
      socketUrl = socketUrl.substring(0, socketUrl.length - 1);
    }

    print('[Socket] Connecting to server at $socketUrl...');
    
    try {
      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket']) // Use WebSocket transport
            .disableAutoConnect() // Disable auto connection on creation
            .build(),
      );

      // Connect manually
      _socket!.connect();

      // Connection lifecycle
      _socket!.onConnect((_) {
        print('[Socket] Connected successfully to server.');
      });

      _socket!.onDisconnect((_) {
        print('[Socket] Disconnected from server.');
      });

      _socket!.onConnectError((data) {
        print('[Socket] Connection Error: $data');
      });

      // Custom events
      _socket!.on('reminder_updated', (data) {
        print('[Socket] Received reminder_updated: $data');
        if (onReminderUpdated != null) {
          onReminderUpdated!(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('reminder_created', (data) {
        print('[Socket] Received reminder_created: $data');
        if (onReminderCreated != null) {
          onReminderCreated!(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('reminder_deleted', (data) {
        print('[Socket] Received reminder_deleted: $data');
        if (onReminderDeleted != null) {
          onReminderDeleted!(data['id'] as int);
        }
      });

      _socket!.on('logs_updated', (_) {
        print('[Socket] Received logs_updated signal.');
        if (onLogsUpdated != null) {
          onLogsUpdated!();
        }
      });

      _socket!.on('team_updated', (_) {
        print('[Socket] Received team_updated signal.');
        if (onTeamUpdate != null) {
          onTeamUpdate!();
        }
      });
    } catch (e) {
      print('[Socket] Error initializing socket: $e');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }
}
