import 'dart:async';
import 'dart:convert';

import 'package:log/log.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:repository/util/hash.dart';
import 'package:util/extension/string.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A client for interacting with the Home Assistant WebSocket API.
class HomeAssistantApi {
  final String baseUrl;
  final String token;
  WebSocketChannel? _channel;
  Completer<List<ShoppingItem>> _responseCompleter = Completer<List<ShoppingItem>>();
  Completer<void> _authCompleter = Completer<void>();
  bool authenticated = false;

  HomeAssistantApi(this.baseUrl, this.token);

  /// Connects and authenticates with the Home Assistant WebSocket API.
  Future<void> connect() {
    _channel = WebSocketChannel.connect(Uri.parse('ws://$baseUrl/api/websocket'));
    _authCompleter = Completer<void>();

    _channel!.stream.listen(
      _handleMessage,
      onDone: _handleConnectionClosed,
      onError: _handleError,
    );

    return _authCompleter.future;
  }

  /// Closes the WebSocket connection.
  void disconnect() {
    if (_channel == null) {
      Log.i('WebSocket connection is not established. Call connect first.');
      return;
    }

    _channel?.sink.close();
    Log.i('Disconnected from Home Assistant WebSocket.');
  }

  /// Fetches to-do data from Home Assistant and parses it.
  Future<List<ShoppingItem>> fetchTodoData(String entityId) async {
    int id = DateTime.now().millisecondsSinceEpoch; // Unique ID for the WebSocket message
    _responseCompleter = Completer<List<ShoppingItem>>();

    var data = {
      'id': id,
      'type': 'call_service',
      'domain': 'todo',
      'service': 'get_items',
      'target': {'entity_id': entityId},
      'return_response': true,
    };

    if (_channel == null) {
      Log.i('WebSocket connection is not established. Call connect first.');
      return [];
    }

    _channel!.sink.add(jsonEncode(data));
    Log.i('Fetching todo data for $entityId...');

    return _responseCompleter.future.timeout(Duration(seconds: 10), onTimeout: () {
      Log.i('Fetching todo data timed out for $entityId.');
      return [];
    });
  }

  List<ShoppingItem> parseTodoData(List<Map<String, dynamic>> items) {
    return items.map((item) {
      final status = item['status'];
      bool checked = status != null && status == 'completed';

      final itemName = item['summary'] as String;
      final uid = item['uid'] as String;

      return ShoppingItem(
        uid: hashBarcode(uid),
        upc: '',
        name: itemName.titleCase,
        checked: checked,
      );
    }).toList();
  }

  /// Handles WebSocket connection closed event.
  void _handleConnectionClosed() {
    Log.i('Connection closed.');
  }

  /// Handles WebSocket errors.
  void _handleError(dynamic error) {
    Log.i('Error: $error');
  }

  /// Handles incoming WebSocket messages.
  void _handleMessage(dynamic message) {
    final response = jsonDecode(message);

    switch (response['type']) {
      case 'auth_required':
        _sendAuth();
        break;
      case 'auth_ok':
        authenticated = true;
        Log.i('Authenticated successfully');
        if (!_authCompleter.isCompleted) {
          _authCompleter.complete();
        }
        break;
      case 'auth_invalid':
        authenticated = false;
        Log.i('Authentication failed: ${response['message']}');
        break;
      case 'result':
        _handleResultMessage(response);
        break;
      default:
        Log.i('Received: ${jsonEncode(response)}');
        break;
    }
  }

  void _handleResultMessage(Map<String, dynamic> response) {
    if (response.containsKey('id')) {
      if (response['success']) {
        try {
          // Extract the entityName
          var responseContent = response['result']['response'];
          var entityName = responseContent.keys.first;

          // Get the items from the response using the given entityName
          List<dynamic> itemsList = responseContent[entityName]['items'];
          List<Map<String, dynamic>> items =
              itemsList.map((item) => item as Map<String, dynamic>).toList();

          // Parse and return the todo data
          final todoData = parseTodoData(items);
          _responseCompleter.complete(todoData);
        } catch (e) {
          _responseCompleter.completeError('Failed to parse items: $e');
        }
      } else {
        _responseCompleter.completeError('Command failed: ${response['error']['message']}');
      }
    } else {
      Log.i('Received an unhandled result: ${jsonEncode(response)}');
    }
  }

  /// Sends the authentication message.
  void _sendAuth() {
    if (_channel == null) {
      Log.i('WebSocket connection is not established. Call connect first.');
      return;
    }

    final authMessage = {
      'type': 'auth',
      'access_token': token,
    };

    _channel!.sink.add(jsonEncode(authMessage));
  }
}
