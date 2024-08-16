import 'package:flutter/material.dart';
import 'package:driver/Widget/OrdersTab/all_orders.dart';
import 'package:driver/Widget/OrdersTab/completed_orders.dart';
import 'package:driver/Widget/OrdersTab/processing_orders.dart';
import 'package:driver/Widget/OrdersTab/accepted_orders.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [
        AllOrders(),
        AcceptedOrders(),
        ProcessingOrders(),
        CompletedOrders(),
        // CancelledOrders()
      ],
    );
  }
}
