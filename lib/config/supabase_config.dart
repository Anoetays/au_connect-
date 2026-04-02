/// Supabase Configuration
/// 
/// Get your Supabase credentials from: https://supabase.com/dashboard/project/lwnblbrohablulbeiruf
/// 
/// Steps:
/// 1. Go to Project Settings > API
/// 2. Copy the Project URL (starts with https://lwnblbrohablulbeiruf.supabase.co)
/// 3. Copy the anon key (starts with eyJ...)
/// 4. Replace the values below

library;

class SupabaseConfig {
  /// Supabase Project URL
  static const String supabaseUrl = 'https://lwnblbrohablulbeiruf.supabase.co';
  
  /// Supabase Anon Key - REPLACE THIS WITH YOUR ACTUAL KEY
  /// Get it from: Project Settings > API > Project API keys > anon public
  static const String supabaseAnonKey = 'sb_publishable_Ar5L2R1tYwaT3gXFMp75mg_4nKbaT8t';
}
