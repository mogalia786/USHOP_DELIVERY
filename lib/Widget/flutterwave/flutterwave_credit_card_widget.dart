// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:uuid/uuid.dart';
import 'flutter_pin_code_widget.dart';

class FlutterwaveCreditCardWidget extends StatefulWidget {
  const FlutterwaveCreditCardWidget({super.key});

  @override
  State<FlutterwaveCreditCardWidget> createState() =>
      _FlutterwaveCreditCardWidgetState();
}

class _FlutterwaveCreditCardWidgetState
    extends State<FlutterwaveCreditCardWidget> {
  bool isLightTheme = false;
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool useGlassMorphism = true;
  bool useBackgroundImage = true;
  bool useFloatingAnimation = true;
  String amount = '';
  String fullname = '';
  String email = '';
  String phone = '';
  String txRef= '';
  

  final OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.grey.withOpacity(0.7),
      width: 2.0,
    ),
  );
  getUserDetail() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(user!.uid)
        .snapshots()
        .listen((event) {
      setState(() {
        fullname = event['fullname'];
        email = event['email'];
        phone = event['phone'];
      });
      //  print('Fullname is $fullName');
    });
  }

  @override
  void initState() {
      var uuid = const Uuid();
    txRef = uuid.v1();
    getUserDetail();
    super.initState();
  }

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Gap(20),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.arrow_back)),
              const SizedBox(width:20),
              Text(
                'Flutterwave Payment',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        CreditCardWidget(
          enableFloatingCard: true,
          glassmorphismConfig: _getGlassmorphismConfig(),
          cardNumber: cardNumber,
          expiryDate: expiryDate,
          cardHolderName: cardHolderName,
          cvvCode: cvvCode,
          bankName: '',
          frontCardBorder:
              useGlassMorphism ? null : Border.all(color: Colors.grey),
          backCardBorder:
              useGlassMorphism ? null : Border.all(color: Colors.grey),
          showBackView: isCvvFocused,
          obscureCardNumber: true,
          obscureCardCvv: true,
          isHolderNameVisible: true,
          backgroundImage: useBackgroundImage ? 'assets/card_bg.png' : null,
          isSwipeGestureEnabled: true,
          onCreditCardWidgetChange: (CreditCardBrand creditCardBrand) {},
          customCardTypeIcons: <CustomCardTypeIcon>[
            CustomCardTypeIcon(
              cardType: CardType.mastercard,
              cardImage: Image.asset(
                'assets/mastercard.png',
                height: 48,
                width: 48,
              ),
            ),
          ],
        ),
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: TextField(
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    setState(() {
                      amount = v;
                    });
                  },
                  decoration: const InputDecoration(hintText: 'Amount'),
                ),
              ),
              CreditCardForm(
                formKey: formKey,
                obscureCvv: true,
                obscureNumber: true,
                cardNumber: cardNumber,
                cvvCode: cvvCode,
                isHolderNameVisible:false,
                isCardNumberVisible: true,
                isExpiryDateVisible: true,
                cardHolderName: cardHolderName,
                expiryDate: expiryDate,
                inputConfiguration: const InputConfiguration(
                  cardNumberDecoration: InputDecoration(
                    labelText: 'Number',
                    hintText: 'XXXX XXXX XXXX XXXX',
                  ),
                  expiryDateDecoration: InputDecoration(
                    labelText: 'Expired Date',
                    hintText: 'XX/XX',
                  ),
                  cvvCodeDecoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: 'XXX',
                  ),
                  cardHolderDecoration: InputDecoration(
                    labelText: 'Card Holder',
                  ),
                ),
                onCreditCardModelChange: onCreditCardModelChange,
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      // backgroundColor: appColor,
                      shape: const BeveledRectangleBorder()),
                  onPressed: () {
                    _onValidate();
                  },
                  child: const Text(
                    'Validate',
                    style: TextStyle(color: Colors.white),
                  ).tr()),
              const Gap(30),
            ],
          ),
        )
      ],
    );
  }

  void _onValidate()async {
    if (formKey.currentState!.validate()  && amount.isNotEmpty) {
      print('valid!');
  await   Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => FlutterPinCodeWidget(
              saveCard: false,
              walletName: cardHolderName,
              cardNumber: cardNumber,
              cvvCode: cvvCode,
              expiryMonth: expiryDate.split('/')[0].trim(),
              expiryYear: expiryDate.split('/').elementAt(1),
              currency: '',
              amount: amount,
              fullname: fullname,
              email: email,
              phone: phone,
              txRef: txRef))).then((value) {
                Navigator.pop(context);
              });
    } else {
      print('invalid!');
    }
  }

  Glassmorphism? _getGlassmorphismConfig() {
    if (!useGlassMorphism) {
      return null;
    }

    final LinearGradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Colors.grey.withAlpha(50), Colors.grey.withAlpha(50)],
      stops: const <double>[0.3, 0],
    );

    return isLightTheme
        ? Glassmorphism(blurX: 8.0, blurY: 16.0, gradient: gradient)
        : Glassmorphism.defaultConfig();
  }

  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }
}
