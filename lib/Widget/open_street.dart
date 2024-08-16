
import 'package:flutter/material.dart';
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';

class OpenStreet extends StatefulWidget {
  const OpenStreet({super.key});

  @override
  State<OpenStreet> createState() => _OpenStreetState();
}

class _OpenStreetState extends State<OpenStreet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Map'),
      ),
      body: OpenStreetMapSearchAndPick(

          // center: LatLong(23, 89),
          // buttonColor: appColor,
          buttonTextStyle: const TextStyle(fontSize: 15, color: Colors.white),
          buttonText: 'Set Current Location',
          onPicked: (pickedData) {
            Navigator.pop(context, pickedData.addressName);
          }),
    );
  }
}
