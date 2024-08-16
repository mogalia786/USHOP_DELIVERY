// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../Model/history.dart';

// ignore: prefer_function_declarations_over_variables
final ControlsWidgetBuilder emptyControlBuilder = (_, __) => Container();

class StripePage extends StatefulWidget {
  final String pkey;
  final String id;
  final String sKey;
  const StripePage(
      {super.key, required this.pkey, required this.sKey, required this.id});

  @override
  State<StripePage> createState() => _StripePageState();
}

class _StripePageState extends State<StripePage> {
  Map<String, dynamic>? paymentIntent;
  String currencyCode = '';
  String currencySymbol = '';
  String name = '';
  num wallet = 0;

  getUserName() {
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(widget.id)
        .get()
        .then((value) {
      name = value['fullname'];
    });
  }

  getCurrencySymbol() {
    FirebaseFirestore.instance
        .collection('Currency Settings')
        .doc('Currency Settings')
        .get()
        .then((value) {
      setState(() {
        currencyCode = value['Currency code'];
        currencySymbol = value['Currency symbol'];
      });
    });
  }

  getWallet() {
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(widget.id)
        .snapshots()
        .listen((value) {
      setState(() {
        wallet = value['wallet'];
      });
    });
    debugPrint('$wallet is your balance');
  }

  updateHistory(HistoryModel historyModel) {
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(widget.id)
        .collection('History')
        .add(historyModel.toMap());
  }

  updateWallet(num amount) {
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(widget.id)
        .update({'wallet': wallet + amount}).then((value) {
      updateHistory(HistoryModel(
          timeCreated:
              DateFormat.yMMMMEEEEd().format(DateTime.now()).toString(),
          message: 'Wallet Upload.',
          amount: '+$currencySymbol$amount',
          paymentSystem: 'Stripe'));

      Fluttertoast.showToast(
          msg: "Wallet has been uploaded with $amount.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);
    });
  }

  @override
  void initState() {
    getWallet();
    getCurrencySymbol();
    getUserName();
    super.initState();
  }

  stripeDetail() async {
    Stripe.publishableKey = widget.pkey;
    Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
    Stripe.urlScheme = 'flutterstripe';
    await Stripe.instance.applySettings();
  }

  int step = 0;
  String amount = '';
  @override
  Widget build(BuildContext context) {
    stripeDetail();
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Stripe Payment',
          style: TextStyle(color: Theme.of(context).iconTheme.color),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                validator: (v) {
                  if (v == '') {
                    return 'Enter Amount'.tr();
                  } else {
                    return null;
                  }
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  labelText: 'Amount'.tr(),
                ),
                onSaved: (String? value) => amount = value!,
                onChanged: (String? value) => amount = value!,
              ),
            ),
            const SizedBox(height: 50),
            Center(
              child: InkWell(
                onTap: () async {
                  await makePayment(amount);
                },
                child: Container(
                  height: 50,
                  color: Colors.orange,
                  child: Center(
                    child: const Text(
                      'Pay',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ).tr(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> makePayment(String amount) async {
    try {
      paymentIntent = await createPaymentIntent('${amount}00', 'GBP');

      var gpay = const PaymentSheetGooglePay(
          merchantCountryCode: "GB", currencyCode: "GBP", testEnv: true);

      //STEP 2: Initialize Payment Sheet
      await Stripe.instance
          .initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                  paymentIntentClientSecret: paymentIntent![
                      'client_secret'], //Gotten from payment intent
                  style: ThemeMode.light,
                  merchantDisplayName: 'Abhi',
                  googlePay: gpay))
          .then((value) {});

      //STEP 3: Display Payment sheet
      displayPaymentSheet();
    } catch (err) {
      print(err);
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        print("Payment Successfully");
        updateWallet(num.parse(amount));
      });
    } catch (e) {
      print('$e');
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${widget.sKey}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      print(json.decode(response.body));
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }
}
