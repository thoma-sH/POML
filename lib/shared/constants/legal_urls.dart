// Single source of truth for the customer-facing URLs and contact email.
// Anything that needs to deep-link to terms, privacy, or support should
// import from here so the values stay in sync across the app.
//
// IMPORTANT: replace these placeholders with the real production URLs and
// support inbox before App Store / Play Store submission. Apple Review
// expects the URLs to resolve to actual published policies, and the support
// address to receive replies within ~24 hours.
class LegalUrls {
  LegalUrls._();

  static const termsOfService = 'https://lacuna.app/terms';
  static const privacyPolicy = 'https://lacuna.app/privacy';
  static const supportEmail = 'support@lacuna.app';
}
