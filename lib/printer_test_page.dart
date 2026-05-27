import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterTestPage extends StatefulWidget {
  const PrinterTestPage({super.key});

  @override
  State<PrinterTestPage> createState() => _PrinterTestPageState();
}

class _PrinterTestPageState extends State<PrinterTestPage> {
  List<BluetoothInfo> devices = [];
  BluetoothInfo? selectedDevice;
  String status = 'Not connected';

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final List<BluetoothInfo> bondedDevices =
        await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      devices = bondedDevices;
    });
  }

 Future<void> _connectPrinter() async {
   setState(() {
     status = 'Connecting...';
   });

   final bool connected = await PrintBluetoothThermal.connect(
     macPrinterAddress: '86:67:7A:C2:A6:BD',
   );

   setState(() {
     status = connected ? 'Connected' : 'Connection failed';
   });
 }

  Future<void> _printTest() async {
    final bool connected = await PrintBluetoothThermal.connectionStatus;

    if (!connected) {
      setState(() {
        status = 'Printer not connected';
      });
      return;
    }

    final String receipt = '''
        MapMyBite Test
------------------------------
Burger x2
Fries x1
------------------------------
Thank You!




''';

    await PrintBluetoothThermal.writeBytes(receipt.codeUnits);
  }

  Future<void> _disconnectPrinter() async {
    await PrintBluetoothThermal.disconnect;
    setState(() {
      status = 'Disconnected';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              status,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            DropdownButton<BluetoothInfo>(
              isExpanded: true,
              hint: const Text('Select Printer'),
              value: selectedDevice,
              items: devices.map((device) {
                return DropdownMenuItem(
                  value: device,
                  child: Text('${device.name} - ${device.macAdress}'),
                );
              }).toList(),
              onChanged: (device) {
                setState(() {
                  selectedDevice = device;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _connectPrinter,
              child: const Text('Connect Printer'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _printTest,
              child: const Text('Print Test Receipt'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _disconnectPrinter,
              child: const Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }
}