// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/Model/formatter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import '../Model/history.dart';

class PaystackPage extends StatefulWidget {
  final String id;
  final String paystackPublicKey;
  final String backendUrl;
  const PaystackPage(
      {super.key,
      required this.paystackPublicKey,
      required this.backendUrl,
      required this.id});

  @override
  State<PaystackPage> createState() => _PaystackPageState();
}

class _PaystackPageState extends State<PaystackPage> {
 final emailController = TextEditingController();
  final amountController = TextEditingController();
  num wallet = 0;
  bool isLoading = true;
  getUserDetail() {
    setState(() {
      isLoading = true;
    });
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(user!.uid)
        .snapshots()
        .listen((event) {
      setState(() {
        isLoading = false;
        wallet = event['wallet'];
      });
      //  print('Fullname is $fullName');
    });
  }

  updateWallet() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    FirebaseFirestore.instance.collection('drivers').doc(user!.uid).update(
        {'wallet': wallet + num.parse(amountController.text)}).then((value) {
      // Get the current date and time
      DateTime now = DateTime.now();

      // Format the date to '24th January, 2024' format
      String formattedDate = DateFormat('d MMMM, y').format(now);
      history(HistoryModel(
          message: 'Credit Alert',
          amount: amountController.text,
          paymentSystem: 'Paystack',
          timeCreated: formattedDate));
      Fluttertoast.showToast(
              msg: "Wallet has been uploaded successfully".tr(),
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              timeInSecForIosWeb: 1,
              fontSize: 14.0)
          .then((value) {
        Navigator.pop(context);
      });
    });
  }

  history(HistoryModel historyModel) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(user!.uid)
        .collection('Transaction History')
        .add(historyModel.toMap());
  }

  @override
  void initState() {
    getUserDetail();
    amountController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  String generateRef() {
    final randomCode = Random().nextInt(3234234);
    return 'ref-$randomCode';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(8),
        //   color: Colors.white,
        // ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center(
            //   child: Row(
            //     children: [
            //       InkWell(
            //           onTap: () {
            //             Navigator.pop(context);
            //           },
            //           child: const Icon(Icons.arrow_back)),
            //       const Gap(20),
            //       Text(
            //         'Paystack Payment',
            //         style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            //               color: Colors.black,
            //               fontWeight: FontWeight.w800,
            //             ),
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 48),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Email'.tr(),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: amountController,
              decoration: InputDecoration(
                hintText: 'Amount(R)'.tr(),
              ),
            ),
            //   const Spacer(),
            const Gap(50),
            TextButton(
              onPressed: isLoading == true
                  ? null
                  : () async {
                      final amount = int.parse(amountController.text);

                      PayWithPayStack().now(
                          context: context,
                          secretKey: dotenv.env['PaystackSecretKey']!,
                          customerEmail: emailController.text,
                          reference:
                              DateTime.now().microsecondsSinceEpoch.toString(),
                          callbackUrl: "",
                          currency: "R",
                          paymentChannel: ["mobile_money", "card"],
                          amount: (amount * 100).toString(),
                          transactionCompleted: () {
                            // ignore: avoid_print
                            print("Transaction Successful");
                            updateWallet();
                         
                          },
                          transactionNotCompleted: () {
                            // ignore: avoid_print
                            print("Transaction Not Successful!");
                            Fluttertoast.showToast(
                                msg: "Transaction Not Successful!".tr(),
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.TOP,
                                timeInSecForIosWeb: 1,
                                fontSize: 14.0);
                          });
                    },
              style: TextButton.styleFrom(
                shape: const BeveledRectangleBorder(),
                backgroundColor: Colors.green[400],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Pay${amountController.text.isEmpty ? '' : ' R${Formatter().converter(double.parse(amountController.text))}'} with Paystack',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
