// lib/constants/api_constants.dart this is the apirui file

class ApiConstants {

  // static const String backendUrl = 'https://agritrack-server.onrender.com';
  static const String backendUrl = 'http://localhost:3001/auth';
  
 
    static const String baseUrl = 'https://aicrop.onrender.com/api/v1';
  // static const String baseUrl = 'http://localhost:8000/api/v1';e

  // static const String baseUrl = 'http://127.0.0.1:8000/api/v1';



  // Auth endpoints
  static const String loginEndpoint = '$backendUrl/login';
  static const String registerEndpoint = '$backendUrl/register';
  static const String verifyEndpoint = '$backendUrl/verify';
  
  // Chatbot endpoints
  static const String chatbotInitEndpoint = '$backendUrl/chatbot/init';
  static const String chatbotMessageEndpoint = '$backendUrl/chatbot/message';
  static const String chatbotClearEndpoint = '$backendUrl/chatbot/clear';
  
  // Other endpoints
  static const String testGeminiEndpoint = '$backendUrl/test-gemini';

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
