import '../config/graphql_config.dart';

Uri getApiBaseUri() {
  final endpoint = GraphQLConfig.endpoint;
  final uri = Uri.parse(endpoint);
  return uri.replace(path: '', query: null, fragment: null);
}

String resolveImageUrl(String url) {
  try {
    final baseUri = getApiBaseUri();
    final sanitizedBase = baseUri.toString().replaceAll(RegExp(r'/+$'), '');

    Uri? parsed;
    try {
      parsed = Uri.parse(url);
    } catch (_) {
      parsed = null;
    }

    if (parsed != null && parsed.hasScheme) {
      if (_isLocalHost(parsed.host)) {
        final sanitizedPath = parsed.path.startsWith('/') ? parsed.path : '/${parsed.path}';
        return '$sanitizedBase$sanitizedPath';
      }
      return url;
    }

    final sanitizedPath = url.startsWith('/') ? url : '/$url';
    return '$sanitizedBase$sanitizedPath';
  } catch (_) {
    return url;
  }
}

bool _isLocalHost(String host) {
  if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
    return true;
  }
  return host.startsWith('192.168.');
}
