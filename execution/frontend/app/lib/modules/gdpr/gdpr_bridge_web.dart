import 'dart:js_interop';

@JS('enableAnalytics')
external void _enableAnalytics();

// Calls window.enableAnalytics() defined in index.html.
// Safe to call multiple times — the JS function guards against double-init.
void callEnableAnalytics() {
  try {
    _enableAnalytics();
  } catch (_) {
    // Function may not be defined if analytics script was not added.
  }
}
