<!DOCTYPE html>
<html lang="en">
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">

  <!-- SEO: tokens replaced automatically by prepare.sh before each build -->
  <title>CLIENT_TITLE</title>
  <meta name="description" content="CLIENT_DESCRIPTION">

  <!-- Open Graph -->
  <meta property="og:type" content="website">
  <meta property="og:title" content="CLIENT_TITLE">
  <meta property="og:description" content="CLIENT_DESCRIPTION">
  <meta property="og:image" content="CLIENT_OG_IMAGE">
  <meta property="og:url" content="CLIENT_URL">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="CLIENT_TITLE">
  <meta name="twitter:description" content="CLIENT_DESCRIPTION">
  <meta name="twitter:image" content="CLIENT_OG_IMAGE">

  <!-- PWA -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="CLIENT_NAME">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="manifest" href="manifest.json">

  <!-- LocalBusiness Structured Data (JSON-LD) -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "LocalBusiness",
    "name": "CLIENT_NAME",
    "description": "CLIENT_DESCRIPTION",
    "url": "CLIENT_URL",
    "telephone": "CLIENT_PHONE",
    "address": {
      "@type": "PostalAddress",
      "streetAddress": "CLIENT_STREET",
      "addressLocality": "CLIENT_CITY",
      "addressRegion": "CLIENT_STATE",
      "postalCode": "CLIENT_ZIP",
      "addressCountry": "CLIENT_COUNTRY"
    },
    "openingHoursSpecification": CLIENT_HOURS_JSON,
    "image": "CLIENT_OG_IMAGE"
  }
  </script>

  <!-- Loading screen — shown until Flutter first frame.
       Tokens CLIENT_COLOR_SURFACE / CLIENT_COLOR_PRIMARY replaced by prepare.sh. -->
  <style>
    html, body {
      margin: 0;
      padding: 0;
      background-color: #CLIENT_COLOR_SURFACE;
    }
    #flutter-loader {
      position: fixed;
      inset: 0;
      background-color: #CLIENT_COLOR_SURFACE;
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 99999;
      transition: opacity 0.35s ease;
    }
    #flutter-loader.hidden {
      opacity: 0;
      pointer-events: none;
    }
    .loader-ring {
      width: 44px;
      height: 44px;
      border: 2px solid rgba(255, 255, 255, 0.08);
      border-top-color: #CLIENT_COLOR_PRIMARY;
      border-radius: 50%;
      animation: loader-spin 0.8s linear infinite;
    }
    @keyframes loader-spin {
      to { transform: rotate(360deg); }
    }
  </style>
</head>
<body>

  <div id="flutter-loader">
    <div class="loader-ring"></div>
  </div>

  <script>
    window.flutterConfiguration = { renderer: "html" };
    window.addEventListener('flutter-first-frame', function () {
      var loader = document.getElementById('flutter-loader');
      if (loader) {
        loader.classList.add('hidden');
        setTimeout(function () { loader.remove(); }, 400);
      }
    });
  </script>
  <script>
    // Service worker registration — required for Web Push (PUSH_ENABLED feature).
    // Always registered so the SW is ready; Flutter gates the permission prompt via AppEnv.pushEnabled.
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js');
    }

    // Push subscription helper — called from Flutter via dart:js_interop.
    // Returns a JSON string with { endpoint, p256dh, auth, userAgent } or null on failure/denial.
    window._pushSubscribe = async function(vapidKey) {
      try {
        var perm = await Notification.requestPermission();
        if (perm !== 'granted') return null;
        var reg = await navigator.serviceWorker.ready;
        var sub = await reg.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: vapidKey,
        });
        var toB64url = function(buf) {
          return btoa(String.fromCharCode.apply(null, new Uint8Array(buf)))
            .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
        };
        return JSON.stringify({
          endpoint:  sub.endpoint,
          p256dh:    toB64url(sub.getKey('p256dh')),
          auth:      toB64url(sub.getKey('auth')),
          userAgent: navigator.userAgent,
        });
      } catch(_) { return null; }
    };
  </script>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
