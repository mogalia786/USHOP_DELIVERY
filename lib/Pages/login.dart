import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:driver/Providers/auth.dart';

import 'package:flutter_close_app/flutter_close_app.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = '';
  String password = '';
  final _formKey = GlobalKey<FormState>();
  Timer? _timer;
  Timer? oneSignalTimer;
  String playerId = '';
  String getOnesignalKey = '';
  bool showPassword = true;

  @override
  void initState() {
    super.initState();

    EasyLoading.addStatusCallback((status) {
      //print('EasyLoading Status $status');
      if (status == EasyLoadingStatus.dismiss) {
        _timer?.cancel();
      }
    });


  getTokenID();
  }


  getTokenID() async {
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      playerId = token!;
    });
  }

 

  final RoundedLoadingButtonController _btnController1 =
      RoundedLoadingButtonController();

  void _doSomething(RoundedLoadingButtonController controller, String email,
      String password, BuildContext context, String playerId) async {
    AuthService().signIn(email, password, context, playerId).then((value) {
      if (AuthService().loginStatus == true) {
        controller.success();
      } else {
        controller.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FlutterCloseAppPage(
        interval: 2,
        condition: true,
        onCloseFailed: () {
          // The interval is more than 2 seconds, or the return key is pressed for the first time
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Press again to exit'),
          ));
        },
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 100),
              Expanded(
                flex: 1,
                child: Image.asset(
                      'assets/image/UShop1024.png',
                    height: 220,
                    // width: 220,
                    fit: BoxFit.cover,
                ),
              ),
              Flexible(
                flex: 5,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: const Text('Login to your account',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold))
                          .tr(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Flexible(
                              flex: 1,
                              child: Icon(
                                Icons.email_outlined,
                                size: 40,
                                color: Colors.grey,
                              )),
                          const SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            flex: 6,
                            child: TextFormField(
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Required field'.tr();
                                } else {
                                  return null;
                                }
                              },
                              onChanged: (value) {
                                setState(() {
                                  email = value;
                                });
                              },
                              decoration: InputDecoration(
                                  hintText: 'Email'.tr(),
                                  focusColor: Colors.orange),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Flexible(
                              flex: 1,
                              child: Icon(
                                Icons.lock_open_outlined,
                                size: 40,
                                color: Colors.grey,
                              )),
                          const SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            flex: 6,
                            child: TextFormField(
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Required field'.tr();
                                } else {
                                  return null;
                                }
                              },
                              onChanged: (value) {
                                setState(() {
                                  password = value;
                                });
                              },
                              obscureText: showPassword,
                              decoration: InputDecoration(
                                hintText: 'Password'.tr(),
                                suffixIcon: showPassword == true
                                    ? InkWell(
                                        onTap: () {
                                          setState(() {
                                            showPassword = false;
                                          });
                                        },
                                        child: const Icon(
                                          Icons.visibility,
                                          color: Colors.grey,
                                          size: 30,
                                        ),
                                      )
                                    : InkWell(
                                        onTap: () {
                                          setState(() {
                                            showPassword = true;
                                          });
                                        },
                                        child: const Icon(
                                          Icons.visibility_off,
                                          color: Colors.grey,
                                          size: 30,
                                        ),
                                      ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            child: Row(
                              children: [
                                const Text('FORGOT PASSWORD',
                                        style: TextStyle(
                                            color: Colors.yellow))
                                    .tr(),
                                const Text('?',
                                    style:
                                        TextStyle(color: Colors.yellow))
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    RoundedLoadingButton(
                      color: Colors.yellow,
                      successIcon: Icons.done,
                      failedIcon: Icons.error,
                      controller: _btnController1,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _doSomething(_btnController1, email, password,
                              context, playerId);
                        } else {
                          _btnController1.reset();
                        }
                      },
                      child: const Text('Login',
                              style: TextStyle(color: Colors.white))
                          .tr(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'New on',
                              style: TextStyle(color: Colors.grey),
                            ).tr(),
                            const SizedBox(width: 5),
                            const Text(
                              'UShop?',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed('/signup');
                          },
                          child: const Text(
                            'CREATE AN ACCOUNT',
                            style: TextStyle(
                                color: Colors.yellow,
                                fontWeight: FontWeight.bold),
                          ).tr(),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: ClipPath(
                  clipper: OvalTopBorderClipper(),
                  child: Container(
                    color: Colors.yellow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
