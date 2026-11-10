/// Flutter API Service for communicating with the FastAPI backend.
/// Handles HTTP requests and WebSocket connections.
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiService {
  // Backend base URL - change this for production
  static const String baseUrl = 'http://localhost:8000';
  static const String wsBaseUrl = 'ws://localhost:8000';

  // -- Nodes --

  /// Fetch all nodes from backend
  static Future<List<Map<String, dynamic>>> getNodes() async {
    final response = await http.get(Uri.parse('$baseUrl/api/nodes'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load nodes: ${response.statusCode}');
  }

  // -- Deployment --

  /// Deploy a single command to selected nodes
  static Future<Map<String, dynamic>> deployCommand({
    required List<String> nodeIds,
    required String command,
    String activityName = '',
    String executionMethod = 'broadcast',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/deploy/command'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'node_ids': nodeIds,
        'command': command,
        'activity_name': activityName,
        'execution_method': executionMethod,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Deploy failed: ${response.statusCode} - ${response.body}');
  }

  /// Deploy multiple commands to selected nodes
  static Future<Map<String, dynamic>> deployCommands({
    required List<String> nodeIds,
    required List<String> commands,
    String activityName = '',
    String executionMethod = 'broadcast',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/deploy/commands'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'node_ids': nodeIds,
        'commands': commands,
        'activity_name': activityName,
        'execution_method': executionMethod,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Deploy failed: ${response.statusCode} - ${response.body}');
  }

  /// Deploy commands from a file
  static Future<Map<String, dynamic>> deployFile({
    required List<String> nodeIds,
    required String fileName,
    required List<int> fileBytes,
    String executionMethod = 'broadcast',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/deploy/file'),
    );
    request.fields['node_ids'] = nodeIds.join(',');
    request.fields['execution_method'] = executionMethod;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Deploy failed: ${response.statusCode} - ${response.body}');
  }

  /// Get deployment status by session ID
  static Future<Map<String, dynamic>> getDeploymentStatus(
      String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/deploy/status/$sessionId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception(
        'Status check failed: ${response.statusCode} - ${response.body}');
  }

  // -- Scheduling --

  /// Fetch all scheduled deployments
  static Future<List<Map<String, dynamic>>> getSchedules() async {
    final response = await http.get(Uri.parse('$baseUrl/api/schedule'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load schedules: ${response.statusCode}');
  }

  /// Create a new scheduled deployment
  static Future<Map<String, dynamic>> createSchedule({
    required String activityName,
    required String scheduleType,
    required String date,
    required String time,
    String? repeatMode,
    String? repeatDay,
    required List<String> nodeIds,
    required List<String> commands,
    String executionMethod = 'broadcast',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/schedule'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'activity_name': activityName,
        'schedule_type': scheduleType,
        'date': date,
        'time': time,
        'repeat_mode': repeatMode,
        'repeat_day': repeatDay,
        'node_ids': nodeIds,
        'commands': commands,
        'execution_method': executionMethod,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Schedule failed: ${response.statusCode} - ${response.body}');
  }

  /// Cancel/remove a scheduled deployment
  static Future<Map<String, dynamic>> cancelSchedule(String scheduleId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/schedule/$scheduleId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Cancel schedule failed: ${response.statusCode} - ${response.body}');
  }

  // -- WebSocket --

  /// Connect to WebSocket for real-time deployment updates
  static WebSocketChannel connectWebSocket(String sessionId) {
    final uri = Uri.parse('$wsBaseUrl/ws/deploy/$sessionId');
    return WebSocketChannel.connect(uri);
  }
}
