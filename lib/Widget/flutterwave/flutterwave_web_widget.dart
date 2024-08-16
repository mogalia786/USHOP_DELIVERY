
import 'package:driver/Widget/flutterwave/flutterwave_credit_card_widget.dart';
import 'package:flutter/material.dart';



class FlutterwaveWebWidget extends StatefulWidget {
  const FlutterwaveWebWidget({super.key});

  @override
  State<FlutterwaveWebWidget> createState() => _FlutterwaveWebWidgetState();
}

class _FlutterwaveWebWidgetState extends State<FlutterwaveWebWidget> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        //  backgroundColor: const Color.fromARGB(255, 238, 237, 237),
        // appBar: AppBar(
        //     // title: const Text('Paystack'),
        //     ),
        body: SingleChildScrollView(
      child: Column(
        children: [
         Padding(
                  padding: EdgeInsets.all(8.0),
                  child: FlutterwaveCreditCardWidget(),
                ),
     
          //const FooterWidget()
        ],
      ),
    ));
  }
}

