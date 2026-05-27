import '../secrets/app_secrets.dart';

class SupabaseConfig {
  static const String url = AppSecrets.supabaseUrl;
  static const String anonKey = AppSecrets.supabaseAnonKey;
  // TODO: Add your Google Web Client ID here from Google Cloud Console
  static const String googleClientId =
      '45530606279-8maahqdog6pc2ja3m19dpciirgku3cgq.apps.googleusercontent.com';
}
