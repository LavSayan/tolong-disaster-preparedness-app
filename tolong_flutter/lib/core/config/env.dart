/// Build-time configuration, supplied with `--dart-define-from-file=env.json`.
///
/// The Supabase publishable (anon) key is a client key protected by Row Level Security.
/// Never put the service-role/secret key or any AI provider key here: anything compiled
/// into the APK can be extracted.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get supabaseConfigured => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Must also be added under Authentication → URL Configuration → Redirect URLs in Supabase.
  static const authRedirectUrl = 'io.tolongapp://login-callback';
}
