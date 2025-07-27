class ApiConfig {
  // Base URL for the backend API
  static const String baseUrl = 'http://localhost:8000';
  
  // API Endpoints
  static const String chatEndpoint = '$baseUrl/chat';
  static const String speechToTextEndpoint = '$baseUrl/speech-to-text';
  static const String textToSpeechEndpoint = '$baseUrl/text-to-speech';
  static const String analyzeImageEndpoint = '$baseUrl/analyze-image';
  
  // Request timeouts (in seconds)
  static const int requestTimeout = 30;
  static const int uploadTimeout = 60;
  
  // Audio configuration
  static const int maxAudioDurationSeconds = 60;
  static const int audioSampleRate = 16000;
  
  // Text limits
  static const int maxTextLength = 1000;
  static const int maxImageDescriptionLength = 500;
}
