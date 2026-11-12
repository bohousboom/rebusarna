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

/// Adresa webu pro sdílené odkazy z mobilní aplikace (na webu se bere aktuální adresa).
/// Nastavit při sestavení: --dart-define=SHARE_BASE_URL=https://tvoje-domena.cz
const String kShareBaseUrl = String.fromEnvironment(
  'SHARE_BASE_URL',
  defaultValue: 'https://rebusarna.vercel.app',
);

/// Odkaz ke stažení Android APK (nejnovější GitHub Release).
const String kAndroidApkUrl =
    'https://github.com/bohousboom/rebusarna/releases/latest/download/rebusarna.apk';

/// Odkaz ke stažení iOS aplikace (App Store / TestFlight). Prázdný = tlačítko je zatím neaktivní.
/// Nastavit při sestavení: --dart-define=IOS_APP_URL=https://apps.apple.com/...
const String kIosAppUrl = String.fromEnvironment('IOS_APP_URL');
