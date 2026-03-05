import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  /// PUBLIC_INTERFACE
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: const Center(
        child: Text(
          'Orders screen\n(deep link: myapp://orders)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
