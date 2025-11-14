// lib/constants/api_constants.dart

class ApiConstants {
  static const String baseUrl = 'https://aicrop.onrender.com/api/v1';
  // static const String baseUrl = 'http://localhost:8000/api/v1';

  // static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  // Prediction endpoints
  static const String predict = '$baseUrl/predict';

  // Suitability endpoints
  static const String checkSuitability = '$baseUrl/check-suitability';
  static const String getSuggestions = '$baseUrl/get-suggestions-stream';

  static const String chatbot = '$baseUrl/chat';

  // Add to your ApiConstants class
  static const String cropRequirements = '$baseUrl/crop-requirements';

  // genai.configure(api_key="AIzaSyCWiZmhjdh1GmYKnvJMLvgsY-bh20wYOZs")  
        // model = genai.GenerativeModel('gemini-2.5-flash')



}
