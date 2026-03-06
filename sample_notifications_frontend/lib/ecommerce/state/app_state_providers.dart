import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'cart_state.dart';
import 'orders_state.dart';
import 'product_state.dart';

class AppStateProviders {
  AppStateProviders._();

  /// PUBLIC_INTERFACE
  /// Root providers for the e-commerce portion of the app.
  static List<SingleChildWidget> build() => <SingleChildWidget>[
        ChangeNotifierProvider<ProductState>(
          create: (_) => ProductState(),
        ),
        ChangeNotifierProvider<CartState>(
          create: (_) => CartState(),
        ),
        ChangeNotifierProvider<OrdersState>(
          create: (_) => OrdersState(),
        ),
      ];
}
