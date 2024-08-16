// import 'package:animations/animations.dart';
// ignore_for_file: avoid_print
import 'dart:async';

import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:list_tile_switch/list_tile_switch.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../Providers/auth.dart';
import '../Theme/theme.dart';
import '../Theme/theme_data.dart';
// import 'categories.dart';
import 'courier.dart';
import 'home.dart';
// import 'search.dart';
import 'package:flutter_close_app/flutter_close_app.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;
  String pageName = 'Feeds'.tr();
  DocumentReference? userRef;
  DocumentReference? userDetails;
  String fullname = 'fetching data...'.tr();
  String email = 'fetching data...'.tr();
  String appName = 'UShop';
  String id = '';
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  Future<void> _getUserDoc() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = auth.currentUser;
    setState(() {
      userRef = firestore.collection('drivers').doc(user!.uid);
    });
  }

  Future<void> _getUserDetails() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    User? user = auth.currentUser;
    setState(() {
      userDetails =
          firestore.collection('drivers').doc(user!.uid).get().then((value) {
        setState(() {
          fullname = value['fullname'].split(' ')[0].trim();
          email = value['email'];
          id = value['id'];
        });
      }) as DocumentReference<Object?>?;
    });
  }

  channgeCurrentPage() {
    setState(() {
      _currentIndex = 2;
      final CurvedNavigationBarState? navBarState =
          _bottomNavigationKey.currentState;
      navBarState?.setPage(2);
    });
  }

  @override
  initState() {
    super.initState();
    _getUserDoc();
    getHistory();
    getAuth();
    _getUserDetails();
    startUpdatingLocation();
    FirebaseMessaging.onMessage.listen(_firebaseMessagingBackgroundHandler);
    requestFCMPermission();
    // await dotenv.load(fileName: ".env");
    if (!kIsWeb) {
      setupFlutterNotifications();
    }
  }

  @pragma('vm:entry-point')
  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await setupFlutterNotifications();
    showFlutterNotification(message);
    startUpdatingLocation();
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.

    print('Handling a background message ${message.messageId}');
  }

  void requestFCMPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('FCM Permission status: ${settings.authorizationStatus}');
  }

  /// Create a [AndroidNotificationChannel] for heads up notifications
  late AndroidNotificationChannel channel;

  bool isFlutterLocalNotificationsInitialized = false;

  Future<void> setupFlutterNotifications() async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    isFlutterLocalNotificationsInitialized = true;
  }

// void _retrieveToken() async {
//   String? token = await FirebaseMessaging.instance.getToken();
//   print('FCM Token: $token');
// }

  void showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'launch_background',
          ),
        ),
      );
    }
    
  }

////////////////////////Location Request ////////////////////
  Future<void> updateLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, handle appropriately
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, handle appropriately
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
// Update the location in Firestore
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void startUpdatingLocation() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(user!.uid)
        .snapshots()
        .listen((v) async {
      if (v['isActive'] == true) {
        Timer.periodic(const Duration(minutes: 2), (timer) async {
          await updateLocation();
        });
      }
    });
  }

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  @override
  void dispose() {
    super.dispose();
  }

  dynamic themeMode;
  var _lightTheme = true;

  void onThemeChanged(bool value, ThemeNotifier themeNotifier) async {
    (value)
        ? themeNotifier.setTheme(lightTheme)
        : themeNotifier.setTheme(darkTheme);
    var prefs = await SharedPreferences.getInstance();
    prefs.setBool('lightMode', value);
  }

  getThemeDetail() async {
    SharedPreferences.getInstance().then((prefs) {
      var lightModeOn = prefs.getBool('lightMode');
      setState(() {
        themeMode = lightModeOn!;
      });
    });
  }

  bool verification = true;

  verificationStatus() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (userRef == null) {
      return null;
    } else {
      return user!.reload().then((value) {
        setState(() {
          verification = user.emailVerified;
          //print(user.emailVerified);
        });
      });
    }
  }

  bool isLogged = false;
  getAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        setState(() {
          isLogged = false;
        });
      } else {
        setState(() {
          isLogged = true;
        });
      }
    });
  }

  openDrawerHome() {
    _scaffoldHome.currentState!.openDrawer();
  }

  final GlobalKey<ScaffoldState> _scaffoldHome = GlobalKey<ScaffoldState>();
  num notification = 0;
  getHistory() {
    return userRef!
        .collection('Notifications')
        .orderBy('timeCreated', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        notification = snapshot.docs.length;
      });
    });
  }

  String hello = 'Hello'.tr();
  @override
  Widget build(BuildContext context) {
    getThemeDetail();
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return FlutterCloseAppPage(
      interval: 2,
      condition: true,
      onCloseFailed: () {
        // The interval is more than 2 seconds, or the return key is pressed for the first time
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Press again to exit'),
        ));
      },
      child: DefaultTabController(
        length: _currentIndex == 0 ? 4 : 0,
        child: Scaffold(
          key: _scaffoldHome,
          drawer: SizedBox(
            width: double.infinity,
            child: Drawer(
              child: ListView(children: [
                DrawerHeader(
                  padding: EdgeInsets.zero,
                  child: Container(
                    // height: 200,
                    color: Colors.yellow,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                color: Colors.black,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.arrow_back)),
                            // IconButton(
                            //     color: Colors.black,
                            //     onPressed: () {},
                            //     icon: const Icon(Icons.call)),
                          ],
                        ),
                        isLogged == false
                            ? const Text('Hello, Guest',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                )).tr()
                            : Text('$hello, $fullname',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                ))
                      ],
                    ),
                  ),
                ),
                ListTile(
                    title: const Text(
                  "Account",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ).tr()),
                ListTile(
                  onTap: () {
                    if (userRef == null) {
                      Navigator.of(context).pushNamed('/login');
                    } else {
                      Navigator.of(context).pushNamed('/bottomNav');
                    }
                  },
                  leading: const Icon(Icons.shopping_bag),
                  title: const Text(
                    "Orders",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ).tr(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => CourierSystem(userID: id))));
                  },
                  leading: const Icon(Icons.delivery_dining),
                  title: const Text(
                    "Logistics/Courier",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ).tr(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  onTap: () {
                    if (userRef == null) {
                      Navigator.of(context).pushNamed('/login');
                    } else {
                      Navigator.of(context).pushNamed('/profile');
                    }
                  },
                  leading: const Icon(Icons.person),
                  title: const Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ).tr(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  onTap: () {
                    if (userRef == null) {
                      Navigator.of(context).pushNamed('/login');
                    } else {
                      Navigator.of(context).pushNamed('/wallet');
                    }
                  },
                  leading: const Icon(Icons.wallet),
                  title: const Text(
                    "Wallet",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ).tr(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  onTap: () {
                    if (userRef == null) {
                      Navigator.of(context).pushNamed('/login');
                    } else {
                      Navigator.of(context).pushNamed('/reviews');
                    }
                  },
                  leading: const Icon(Icons.reviews),
                  title: const Text(
                    "Reviews",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ).tr(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(
                  endIndent: 10,
                  indent: 10,
                  color: Colors.grey,
                  thickness: 1,
                ),
                ListTile(
                  onTap: () {
                    Navigator.of(context).pushNamed('/faq');
                  },
                  leading: const Icon(Icons.help_center_rounded),
                  title: const Text(
                    "F.A.Q.",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ).tr(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  onTap: () {
                    if (userRef == null) {
                      Navigator.of(context).pushNamed('/login');
                    } else {
                      Navigator.of(context).pushNamed('/inbox');
                    }
                  },
                  leading: const Icon(Icons.notifications),
                  title: const Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ).tr(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  onTap: () {
                    Navigator.of(context).pushNamed('/language-settings');
                  },
                  leading: const Icon(Icons.language),
                  title: const Text(
                    "Language",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ).tr(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTileSwitch(
                    switchActiveColor: Colors.yellow,
                    leading: const Icon(Icons.color_lens),
                    title: const Text('Theme Mode',
                        style: TextStyle(
                          fontSize: 18,
                        )).tr(),
                    // ignore: prefer_if_null_operators
                    value: themeMode == null ? true : themeMode,
                    onChanged: (val) {
                      setState(() {
                        _lightTheme = val;
                        themeMode = val;
                      });
                      onThemeChanged(val, themeNotifier);
                      debugPrint(_lightTheme.toString());
                    }),
                isLogged == true
                    ? ListTile(
                        onTap: () {
                          AuthService().signOut(context);
                        },
                        leading: const Icon(Icons.logout),
                        title: const Text(
                          "Log Out",
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ).tr(),
                      )
                    : ListTile(
                        onTap: () {
                          Navigator.of(context).pushNamed('/login');
                        },
                        leading: const Icon(Icons.login),
                        title: const Text(
                          "Log in",
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ).tr(),
                      ),
              ]),
            ),
          ),
          appBar: AppBar(
            actions: [
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/inbox');
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 236, 230, 230)),
                    child: Badge(
                      badgeStyle: const BadgeStyle(
                        badgeColor: Colors.orange,
                      ),
                      badgeContent: Text(
                        notification.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.notifications,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
            leading: InkWell(
              onTap: () {
                openDrawerHome();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromARGB(255, 236, 230, 230)),
                  child: const Icon(
                    Icons.person,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.yellow,
            centerTitle: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            bottom: TabBar(
              // indicatorColor: Colors.white,
              isScrollable: true,
              // labelColor: Colors.white,
              tabs: [
                Tab(text: 'All'.tr()),
                Tab(text: 'Accepted'.tr()),
                Tab(text: 'Processing'.tr()),
                Tab(text: 'Completed'.tr()),
              ],
            ),
          ),
          body: FlutterCloseAppPage(
              interval: 2,
              condition: true,
              onCloseFailed: () {
                // The interval is more than 2 seconds, or the return key is pressed for the first time
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Press again to exit'),
                ));
              },
              child: const HomePage()),
        ),
      ),
    );
  }
}

DateTime? backbuttonpressedTime;
Future<bool> onWillPop() async {
  DateTime currentTime = DateTime.now();
  //Statement 1 Or statement2
  bool backButton = currentTime.difference(backbuttonpressedTime!) >
      const Duration(seconds: 1);
  if (backButton) {
    backbuttonpressedTime = currentTime;
    Fluttertoast.showToast(
        msg: "Tap again to leave",
        backgroundColor: Colors.black,
        textColor: Colors.white);

    return false;
  }

  SystemChannels.platform.invokeMethod('SystemNavigator.pop');

  return true;
}
