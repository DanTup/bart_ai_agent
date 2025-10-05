import 'package:bart/api/openai_client.dart';

class OllamaClient extends OpenAIClient {
  OllamaClient({
    super.apiUrl = 'http://localhost:11434/v1/chat/completions',
    super.apiKey = 'OLLAMA',
    required super.model,
  });
}
