class ApiEndpoints {
  // Base URLs
  static const String baseUrl = 'http://localhost:3001/api/v1';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  
  // Dashboard endpoints
  static const String dashboardSummary = '/dashboard/summary';
  
  // Profile endpoints
  static const String userProfile = '/profile';

   static const String createPaymentIntent = '/payment/create-payment-intent';
  
  // Add more endpoints as needed...
}