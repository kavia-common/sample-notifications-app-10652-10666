import 'package:intl/intl.dart';

/// Money formatting helpers for the e-commerce demo.
class Money {
  Money._();

  /// PUBLIC_INTERFACE
  /// Formats a cents amount into a localized currency string.
  ///
  /// Example: 12999 + 'usd' -> "$129.99" (in en_US locale).
  static String formatCents({
    required int cents,
    required String currencyCode,
    String? locale,
  }) {
    final NumberFormat fmt = NumberFormat.simpleCurrency(
      name: currencyCode.toUpperCase(),
      locale: locale,
    );
    return fmt.format(cents / 100.0);
  }
}
