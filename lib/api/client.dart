import 'package:bart/api/types.dart';

abstract class ApiClient {
  Future<APIResponse> callAPI(
    List<Message> messages,
    List<ToolDefinition> tools,
  );
}
