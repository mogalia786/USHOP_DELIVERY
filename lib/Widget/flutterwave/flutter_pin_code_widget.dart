// ignore_for_file: avoid_print
import 'package:driver/Model/constant.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pinput/pinput.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'flutterwave_otp_widget.dart';


class FlutterPinCodeWidget extends StatefulWidget {
  final String cardNumber;
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
  final bool saveCard;

  const FlutterPinCodeWidget(
      {super.key,
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
      required this.saveCard});

  @override
  State<FlutterPinCodeWidget> createState() => _FlutterPinCodeWidgetState();
}

class _FlutterPinCodeWidgetState extends State<FlutterPinCodeWidget> {
  List data = [];
  List cardDetails = [];
  String flwRef = '';
  String pin = '';
  String cardType = '';
  bool status = false;
  String lastDigits = '';
  String firstDigits = '';

  initializeCard(
    String cardNumber,
    String cvvCode,
    String expiryMonth,
    String expiryYear,
    String currency,
    String amount,
    String fullname,
    String email,
    String phone,
  ) async {
    var url = Uri.parse(
      serverUrl,
    );
    List allResponse = [];
    List cardList = [];
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
              "card_number": cardNumber.split(" ").join(""),
              "cvv": cvvCode,
              "expiry_month": expiryMonth,
              "expiry_year": expiryYear,
              "currency": currency,
              "amount": amount,
              "tx_ref": widget.txRef,
              "fullname": fullname,
              "email": email,
              "phone_number": phone,
              "redirect_url": 'http://localhost:3000/pay/redirect',
              "enckey": dotenv.env['encKey'],
              "authorization": {"mode": "pin", "pin": pin}
            }))
        .then((value) async {
      try {
        //  print(value.body);

        var responseData = json.decode(value.body);
        allResponse.add(responseData);
        cardList.add(responseData);
        for (var element in allResponse) {
          data.add(element['data']);
          data.map((e) {
            setState(() {
              flwRef = e["flw_ref"];
            });
          }).toList();
        }
        for (var element in data) {
          cardDetails.add(element['card']);
          cardDetails.map((e) {
            setState(() {
              lastDigits = e["last_4digits"];
              firstDigits = e["first_6digits"];
              cardType = e['type'];
            });
          }).toList();
        }
        // print(value.statusCode);
        if (value.statusCode == 200) {
          setState(() {
            status = false;
          });
          Fluttertoast.showToast(
              msg: 'OTP sent successfully.',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              timeInSecForIosWeb: 1,
              fontSize: 14.0);
          await Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (context) => FlutterOTPWidget(
                        firstDigits: firstDigits,
                        lastDigits: lastDigits,
                        cardType: cardType,
                        saveCard: widget.saveCard,
                        walletName: widget.walletName,
                        cardNumber: cardNumber,
                        cvvCode: cvvCode,
                        expiryMonth: widget.expiryMonth,
                        expiryYear: widget.expiryYear,
                        currency: widget.currency,
                        amount: widget.amount,
                        fullname: fullname,
                        email: email,
                        phone: phone,
                        txRef: widget.txRef,
                        flwRef: flwRef,
                      )))
              .then((value) {
            Navigator.pop(context);
          });
        } else {
          setState(() {
            status = false;
          });
          Fluttertoast.showToast(
              msg: 'An error occurred please try again',
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

  final pinController = TextEditingController();
  final focusNode = FocusNode();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
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
          'Enter Pin Code',
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
            const Text('Enter Your Pin Code',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(
              height: 50,
            ),
            Center(
              child: Directionality(
                // Specify direction if desired
                textDirection: TextDirection.ltr,
                child: Pinput(
                  controller: pinController,
                  focusNode: focusNode,
                  androidSmsAutofillMethod:
                      AndroidSmsAutofillMethod.smsUserConsentApi,
                  listenForMultipleSmsOnAndroid: true,
                  defaultPinTheme: defaultPinTheme,
                  validator: (value) {
                    return value != '' ? null : 'Pin is required';
                  },
                  // onClipboardFound: (value) {
                  //   debugPrint('onClipboardFound: $value');
                  //   pinController.setText(value);
                  // },
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
                          initializeCard(
                              widget.cardNumber,
                              widget.cvvCode,
                              widget.expiryMonth,
                              widget.expiryYear,
                              "",
                              widget.amount,
                              widget.fullname,
                              widget.email,
                              widget.phone);
                        }
                      },
                      child: const Text('Send OTP')),
            ),
          ],
        ),
      ),
    );
  }
}
