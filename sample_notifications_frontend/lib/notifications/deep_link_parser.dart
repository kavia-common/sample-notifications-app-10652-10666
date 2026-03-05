import 'dart:core';

/// Helpers for parsing deep-links like:
/// - myapp://orders
/// - myapp://chat?threadId=42
class DeepLinkParser {
  DeepLinkParser._();

  /// PUBLIC_INTERFACE
  /// Parses a deep link into an in-app route location usable by go_router.
  ///
  /// Supported inputs:
  /// - "myapp://orders" -> "/orders"
  /// - "myapp://chat?threadId=42" -> "/chat?threadId=42"
  /// - "/orders" -> "/orders" (already a route)
  ///
  /// Returns null if the input is empty/invalid.
  static String? toRouterLocation(String? deepLink) {
    if (deepLink == null) return null;
    final String trimmed = deepLink.trim();
    if (trimmed.isEmpty) return null;

    // If it's already a go_router-style location, keep it.
    if (trimmed.startsWith('/')) return trimmed;

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return null;
    }

    // Accept our custom scheme deep links.
    if (uri.scheme == 'myapp') {
      // For "myapp://orders" -> host is "orders", path is empty.
      // For "myapp://chat?threadId=42" -> host is "chat".
      final String route = uri.host.isNotEmpty ? '/${uri.host}' : uri.path;
      final String normalizedRoute = route.startsWith('/') ? route : '/$route';

      final String query = uri.query;
      if (query.isEmpty) return normalizedRoute;
      return '$normalizedRoute?$query';
    }

    // As a fallback, accept https links that contain a path we can route to
    // (not required by this task, but makes the app more robust).
    if (uri.hasScheme && uri.path.isNotEmpty) {
      final String route = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      final String query = uri.query;
      if (query.isEmpty) return route;
      return '$route?$query';
    }

    return null;
  }
}
