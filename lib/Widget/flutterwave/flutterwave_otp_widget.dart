// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/Model/constant.dart';
import 'package:driver/Model/history.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pinput/pinput.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;



class FlutterOTPWidget extends StatefulWidget {
  final String cardNumber;
  final String cardType;
  final String cvvCode;
  final String expiryMonth;
  final String expiryYear;
  final String currency;
  final String amount;
  final String fullname;
  final String email;
  final String phone;
  final String txRef;
  final String walletName;
  final String flwRef;
  final bool saveCard;
  final String lastDigits;
  final String firstDigits;

  const FlutterOTPWidget({
    super.key,
    required this.cardNumber,
    required this.cvvCode,
    required this.expiryMonth,
    required this.expiryYear,
    required this.currency,
    required this.amount,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.txRef,
    required this.walletName,
    required this.flwRef,
    required this.saveCard,
    required this.cardType,
    required this.lastDigits,
    required this.firstDigits,
  });

  @override
  State<FlutterOTPWidget> createState() => _FlutterOTPWidgetState();
}

class _FlutterOTPWidgetState extends State<FlutterOTPWidget> {
  List data = [];
  String flwRef = '';
  String pin = '';
  bool status = false;
  String lastDigits = '';
  String token = '';
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

  updateWalletByCurrency(
    String currency,
    String amount,
  ) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = auth.currentUser;
    firestore
        .collection('drivers')
        .doc(user!.uid)
        .update({'wallet': wallet + num.parse(widget.amount)});
    // Get the current date and time
    DateTime now = DateTime.now();

    // Format the date to '24th January, 2024' format
    String formattedDate = DateFormat('d MMMM, y').format(now);
    history(HistoryModel(
        message: 'Credit Alert',
        amount: widget.amount,
        paymentSystem: 'Flutterwave',
        timeCreated: formattedDate));
           Navigator.pop(context);
    Fluttertoast.showToast(
        msg: "Wallet has been uploaded successfully".tr(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        fontSize: 14.0);
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

  sendOTP(String pin, String flwRef) async {
    var url = Uri.parse(
      '$serverUrl/otp',
    );
    List allResponse = [];
    setState(() {
      status = true;
    });
    await http
        .post(url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              "otp": pin,
              "flw_ref": flwRef,
            }))
        .then((value) {
      var responseData = json.decode(value.body);
      allResponse.add(responseData);
      try {
        for (var element in allResponse) {
          data.add(element['data']);
          data.map((e) {
            if (e['status'] == 'successful') {
              setState(() {
                verifyTransaction(e["id"]);
              });
            } else {
              setState(() {
                status = false;
              });
              Fluttertoast.showToast(
                  msg: e['status'],
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.TOP,
                  timeInSecForIosWeb: 1,
                  fontSize: 14.0);
            }
          }).toList();
        }
      } catch (e) {
        setState(() {
          status = false;
        });
        Fluttertoast.showToast(
            msg: jsonDecode(value.body.toString())["message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            timeInSecForIosWeb: 1,
            fontSize: 14.0);
      }
    });
  }

  verifyTransaction(int pin) async {
    var url = Uri.parse(
      '$serverUrl/verify-transaction',
    );
    List allResponse = [];
    List cardDetails = [];
    List data2 = [];
    String dataStatus = '';
    await http
        .post(url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              "id": pin,
            }))
        .then((value) {
      try {
        var responseData = json.decode(value.body);
        allResponse.add(responseData);
        for (var element in allResponse) {
          data.add(element['data']);
          data.map((e) {
            setState(() {
              dataStatus = e['status'];
            });
          }).toList();
        }
        if (dataStatus == 'successful') {
          for (var element in allResponse) {
            data2.add(element['data']);
            data2.map((e) {
              setState(() {
                cardDetails.add(e['card']);
              });
            }).toList();
          }
          cardDetails.map((e) {
            setState(() {
              token = e['token'];
            });
          }).toList();

          updateWalletByCurrency(
            widget.currency,
            widget.amount,
          );

          setState(() {
            status = false;
          });
          Fluttertoast.showToast(
              msg: 'Funds has been added successfully.',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              timeInSecForIosWeb: 1,
              fontSize: 14.0);
      
        } else if (dataStatus == 'pending') {
          verifyTransactionQueue(pin);
        } else {
          setState(() {
            status = false;
          });
          Fluttertoast.showToast(
              msg: dataStatus,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              timeInSecForIosWeb: 1,
              fontSize: 14.0);
        }
      } catch (e) {
        setState(() {
          status = false;
        });
        Fluttertoast.showToast(
            msg: jsonDecode(value.body.toString())["message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            timeInSecForIosWeb: 1,
            fontSize: 14.0);
      }
    });
  }

  verifyTransactionQueue(int pin) async {
    var url = Uri.parse(
      '$serverUrl/verify-transaction-queue',
    );

    await http
        .post(url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              "id": pin,
            }))
        .then((value) {
      try {
        verifyTransaction(pin);
      } catch (e) {
        setState(() {
          status = false;
        });
        Fluttertoast.showToast(
            msg: jsonDecode(value.body.toString())["message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            timeInSecForIosWeb: 1,
            fontSize: 14.0);
      }
    });
  }

  final pinController = TextEditingController();
  final focusNode = FocusNode();
  final formKey = GlobalKey<FormState>();
  String id = '';

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    var uuid = const Uuid();
    getUserDetail();
    id = uuid.v1();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const focusedBorderColor = Color.fromRGBO(23, 171, 144, 1);
    const fillColor = Color.fromRGBO(243, 246, 249, 0);
    const borderColor = Color.fromRGBO(23, 171, 144, 0.4);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
    );

    /// Optionally you can use form to validate the Pinput
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Enter OTP Code',
        ),
      ),
      body: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          const SizedBox(
              height: 20,
            ),
            const Text('Enter OTP Code',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(
              height: 50,
            ),
            Center(
              child: Directionality(
                // Specify direction if desired
                textDirection: ui.TextDirection.ltr,
                child: Pinput(
                  length: 5,
                  controller: pinController,
                  focusNode: focusNode,
                  androidSmsAutofillMethod:
                      AndroidSmsAutofillMethod.smsUserConsentApi,
                  listenForMultipleSmsOnAndroid: true,
                  defaultPinTheme: defaultPinTheme,
                  validator: (value) {
                    return value != '' ? null : 'Pin is required';
                  },
                  hapticFeedbackType: HapticFeedbackType.lightImpact,
                  onCompleted: (pin) {
                    debugPrint('onCompleted: $pin');
                  },
                  onChanged: (value) {
                    debugPrint('onChanged: $value');
                    setState(() {
                      pin = value;
                    });
                  },
                  cursor: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        width: 22,
                        height: 1,
                        color: focusedBorderColor,
                      ),
                    ],
                  ),
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: focusedBorderColor),
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: focusedBorderColor),
                    ),
                  ),
                  errorPinTheme: defaultPinTheme.copyBorderWith(
                    border: Border.all(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: status == true
                  ? const ElevatedButton(
                      onPressed: null, child: Text('Please wait...'))
                  : ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          sendOTP(pin, widget.flwRef);
                        }
                      },
                      child: const Text('Charge Card')),
            ),
          ],
        ),
      ),
    );
  }
}
