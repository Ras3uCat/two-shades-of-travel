import 'package:web/web.dart' as web;

void setDocumentTitle(String title) {
  web.document.title = title;
}

void setMetaContent(String name, String content) {
  final selector = 'meta[name="$name"], meta[property="$name"]';
  var element = web.document.querySelector(selector) as web.HTMLMetaElement?;

  if (element == null) {
    element = web.document.createElement('meta') as web.HTMLMetaElement;
    if (name.startsWith('og:')) {
      element.setAttribute('property', name);
    } else {
      element.name = name;
    }
    web.document.head!.appendChild(element);
  }

  element.content = content;
}

void setCanonical(String url) {
  var element =
      web.document.querySelector('link[rel="canonical"]')
          as web.HTMLLinkElement?;

  if (element == null) {
    element = web.document.createElement('link') as web.HTMLLinkElement;
    element.rel = 'canonical';
    web.document.head!.appendChild(element);
  }

  element.href = url;
}

void injectJsonLd(String id, String json) {
  final scriptId = 'ld-$id';
  var element = web.document.getElementById(scriptId) as web.HTMLScriptElement?;

  if (element == null) {
    element = web.document.createElement('script') as web.HTMLScriptElement;
    element.type = 'application/ld+json';
    element.id = scriptId;
    web.document.head!.appendChild(element);
  }

  element.text = json;
}

void removeJsonLd(String id) {
  final scriptId = 'ld-$id';
  web.document.getElementById(scriptId)?.remove();
}
