/// Supabase: URL a publishable (veřejný) klíč. Jsou určené pro klientské aplikace,
/// přístup chrání pravidla (RLS) v databázi. NIKDY sem nevkládej `service_role` klíč.
/// Přepsat jdou při sestavení: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://hoxamlazjfkkrlywnehw.supabase.co',
);

const String kSupabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_YVMyH44WATMlo-3C3pVkfQ_IkWHY7Dk',
);

/// Návratová adresa po přihlášení v mobilní aplikaci (musí být i v nastavení Supabase
/// a v AndroidManifest.xml / Info.plist).
const String kMobileAuthRedirect = 'cz.rebusarna://login-callback';
