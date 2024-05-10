import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';

import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BLEPage(),
    );
  }
}

class BLEPage extends StatefulWidget {
  @override
  _BLEPageState createState() => _BLEPageState();
}

class _BLEPageState extends State<BLEPage> {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final TextEditingController textEditingController = TextEditingController();
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  @override
  void initState() {
    super.initState();
    flutterBlue.connectedDevices
        .then((devices) {
      for (BluetoothDevice device in devices) {
        print('Already connected to ${device.name}');
      }
    });
    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        print('${result.device.name} found! rssi: ${result.rssi}');
      }
    });
    flutterBlue.startScan(timeout: Duration(seconds: 4));
  }

  @override
  void dispose() {
    flutterBlue.stopScan();
    super.dispose();
  }

  void sendMessage(String message) async {
    if (characteristic != null) {
      List<int> bytes = utf8.encode(message);
      await characteristic!.write(bytes);
      print('Message sent: $message');
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      // 特定のサービスUUIDを探す、例えばハートレートモニター
      if (service.uuid.toString() == "0000180d-0000-1000-8000-00805f9b34fb") {
        service.characteristics.forEach((char) {
          // 特定のキャラクタリスティックUUIDを探す
          if (char.uuid.toString() == "00002a37-0000-1000-8000-00805f9b34fb") {
            setState(() {
              this.device = device;
              characteristic = char;  // ここで対象のキャラクタリスティックを保持
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BLE Communication"),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: textEditingController,
            decoration: InputDecoration(
              labelText: 'Send a message',
              suffixIcon: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => sendMessage(textEditingController.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
