/// AppEnv — single source of all dart-define values.
/// All values are injected at build time via:
///   flutter build web --dart-define-from-file=client.json
///
/// NEVER call String.fromEnvironment() anywhere else in the codebase.
/// NEVER hardcode fallback brand values — use client.json.example as reference.
class AppEnv {
  AppEnv._();

  // ─── Identity ────────────────────────────────────────────────────────────
  static const clientName = String.fromEnvironment('CLIENT_NAME');
  static const clientSlug = String.fromEnvironment('CLIENT_SLUG');

  // ─── Personality & Layout ────────────────────────────────────────────────
  /// One of: luxury | minimal | bold | warm | corporate
  static const personality = String.fromEnvironment(
    'PERSONALITY',
    defaultValue: 'minimal',
  );

  /// One of: fullbleed | split | centered | video_bg
  static const heroVariant = String.fromEnvironment(
    'HERO_VARIANT',
    defaultValue: 'fullbleed',
  );

  /// One of: overlay | sticky | sidebar | minimal
  static const navStyle = String.fromEnvironment(
    'NAV_STYLE',
    defaultValue: 'sticky',
  );

  /// Comma-separated section order: hero,services,team,testimonials,cta
  static const homeSections = String.fromEnvironment(
    'HOME_SECTIONS',
    defaultValue: 'hero,services,cta',
  );

  // ─── Brand Colors (hex strings without #) ────────────────────────────────
  static const colorPrimary = String.fromEnvironment(
    'COLOR_PRIMARY',
    defaultValue: '6750A4',
  );
  static const colorSecondary = String.fromEnvironment(
    'COLOR_SECONDARY',
    defaultValue: '625B71',
  );
  static const colorAccent = String.fromEnvironment(
    'COLOR_ACCENT',
    defaultValue: '7D5260',
  );
  static const colorSurface = String.fromEnvironment(
    'COLOR_SURFACE',
    defaultValue: 'FFFBFE',
  );
  static const colorOnSurface = String.fromEnvironment(
    'COLOR_ON_SURFACE',
    defaultValue: '1C1B1F',
  );
  static const colorError = String.fromEnvironment(
    'COLOR_ERROR',
    defaultValue: 'B3261E',
  );

  // ─── Fonts ───────────────────────────────────────────────────────────────
  static const fontPrimary = String.fromEnvironment(
    'FONT_PRIMARY',
    defaultValue: 'Inter',
  );
  static const fontSecondary = String.fromEnvironment(
    'FONT_SECONDARY',
    defaultValue: 'Inter',
  );

  // ─── Locale & Business ───────────────────────────────────────────────────
  static const timezone = String.fromEnvironment(
    'TIMEZONE',
    defaultValue: 'America/New_York',
  );
  static const stripeMode = String.fromEnvironment(
    'STRIPE_MODE',
    defaultValue: 'standard',
  );
  static const siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // ─── Location & Contact (used in SEO / JSON-LD) ──────────────────────────
  static const city = String.fromEnvironment('CITY', defaultValue: '');
  static const state = String.fromEnvironment('STATE', defaultValue: '');
  static const zip = String.fromEnvironment('ZIP', defaultValue: '');
  static const country = String.fromEnvironment('COUNTRY', defaultValue: '');
  static const street = String.fromEnvironment('STREET', defaultValue: '');
  static const phone = String.fromEnvironment('PHONE', defaultValue: '');
  static const gdprEnabled = bool.fromEnvironment(
    'GDPR_ENABLED',
    defaultValue: false,
  );
  static const googleAuthEnabled = bool.fromEnvironment(
    'GOOGLE_AUTH_ENABLED',
    defaultValue: false,
  );
  static const appleAuthEnabled = bool.fromEnvironment(
    'APPLE_AUTH_ENABLED',
    defaultValue: false,
  );

  // ─── Social links (empty = not shown) ────────────────────────────────────
  static const instagramUrl = String.fromEnvironment(
    'INSTAGRAM_URL',
    defaultValue: '',
  );
  static const facebookUrl = String.fromEnvironment(
    'FACEBOOK_URL',
    defaultValue: '',
  );
  static const tiktokUrl = String.fromEnvironment(
    'TIKTOK_URL',
    defaultValue: '',
  );
  static const youtubeUrl = String.fromEnvironment(
    'YOUTUBE_URL',
    defaultValue: '',
  );

  // ─── Add-on features ─────────────────────────────────────────────────────
  static const smsEnabled = bool.fromEnvironment(
    'SMS_ENABLED',
    defaultValue: false,
  );
  static const intakeEnabled = bool.fromEnvironment(
    'INTAKE_ENABLED',
    defaultValue: false,
  );
  static const loyaltyEnabled = bool.fromEnvironment(
    'LOYALTY_ENABLED',
    defaultValue: false,
  );
  static const giftEnabled = bool.fromEnvironment(
    'GIFT_ENABLED',
    defaultValue: false,
  );
  static const waitlistEnabled = bool.fromEnvironment(
    'WAITLIST_ENABLED',
    defaultValue: false,
  );
  static const packagesEnabled = bool.fromEnvironment(
    'PACKAGES_ENABLED',
    defaultValue: false,
  );
  static const reviewsEnabled = bool.fromEnvironment(
    'REVIEWS_ENABLED',
    defaultValue: false,
  );
  static const clientPhotosEnabled = bool.fromEnvironment(
    'CLIENT_PHOTOS_ENABLED',
    defaultValue: false,
  );
  static const recurringEnabled = bool.fromEnvironment(
    'RECURRING_ENABLED',
    defaultValue: false,
  );
  static const coursesEnabled = bool.fromEnvironment(
    'COURSES_ENABLED',
    defaultValue: false,
  );
  static const tipEnabled = bool.fromEnvironment('TIP_ENABLED', defaultValue: false);
  static const digestEnabled = bool.fromEnvironment('DIGEST_ENABLED', defaultValue: false);
  static const chatbotEnabled = bool.fromEnvironment('CHATBOT_ENABLED', defaultValue: false);
  static const chatbotFull = String.fromEnvironment('CHATBOT_MODE') == 'full';
  static const pushEnabled = bool.fromEnvironment('PUSH_ENABLED', defaultValue: false);
  static const stripeInvoicingEnabled = bool.fromEnvironment('STRIPE_INVOICING_ENABLED', defaultValue: false);
  static const invoicesEnabled = bool.fromEnvironment('INVOICES_ENABLED', defaultValue: false);
  static const reviewsSyncEnabled = bool.fromEnvironment('REVIEWS_SYNC_ENABLED', defaultValue: false);
  static const locationsEnabled = bool.fromEnvironment('LOCATIONS_ENABLED', defaultValue: false);
  static const fcmEnabled = bool.fromEnvironment('FCM_ENABLED', defaultValue: false);
  static const vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');

  // ─── Modules ─────────────────────────────────────────────────────────────
  /// Comma-separated list: home,contact,auth,booking,newsletter,crm
  static const _modulesRaw = String.fromEnvironment(
    'MODULES',
    defaultValue: 'home,contact,auth',
  );
  static List<String> get modules => _modulesRaw
      .split(',')
      .map((m) => m.trim())
      .where((m) => m.isNotEmpty)
      .toList();

  // ─── Credentials (server-adjacent only — publishable/anon keys) ──────────
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const stripePk = String.fromEnvironment('STRIPE_PK');

  // ─── Helpers ─────────────────────────────────────────────────────────────
  /// System modules are always enabled regardless of the MODULES env var.
  static const _systemModules = {'auth', 'admin'};
  static bool moduleEnabled(String id) =>
      _systemModules.contains(id) || modules.contains(id);

  static List<String> get homeSectionList => homeSections
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
