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
    final bondedDevices = await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      devices = bondedDevices;
      if (devices.isNotEmpty) {
        selectedDevice = devices.first;
      }
    });
  }

  Future<void> _connectPrinter() async {
    if (selectedDevice == null) {
      setState(() => status = 'Please select a printer first');
      return;
    }

    setState(() => status = 'Connecting...');

    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: selectedDevice!.macAdress,
    );

    setState(() {
      status = connected
          ? 'Connected to ${selectedDevice!.name}'
          : 'Connection failed';
    });
  }

  String _line() => '--------------------------------\n';

  String _row(String left, String right) {
    const width = 32;
    final space = width - left.length - right.length;
    return '$left${' ' * (space > 1 ? space : 1)}$right\n';
  }

  Future<void> _printTest() async {
    final connected = await PrintBluetoothThermal.connectionStatus;

    if (!connected) {
      setState(() => status = 'Printer not connected');
      return;
    }

    final receipt = StringBuffer();

    receipt.writeln('          MAPMYBITE');
    receipt.writeln('      POS TEST RECEIPT');
    receipt.write(_line());
    receipt.writeln('Business: Taco Truck Demo');
    receipt.writeln('Order #: 1001');
    receipt.writeln('Customer: Walk-in');
    receipt.writeln('Payment: Pay at Counter');
    receipt.write(_line());

    receipt.write(_row('2 x Veggie Taco', '\$7.98'));
    receipt.write(_row('1 x Fries', '\$3.99'));
    receipt.write(_row('1 x Mango Drink', '\$4.50'));

    receipt.write(_line());
    receipt.write(_row('Subtotal', '\$16.47'));
    receipt.write(_row('Tax', '\$1.36'));
    receipt.write(_row('TOTAL', '\$17.83'));
    receipt.write(_line());

    receipt.writeln('Thank you for your order!');
    receipt.writeln('Powered by MapMyBite');
    receipt.writeln('\n\n\n');

    await PrintBluetoothThermal.writeBytes(receipt.toString().codeUnits);

    setState(() => status = 'Receipt printed');
  }

  Future<void> _disconnectPrinter() async {
    await PrintBluetoothThermal.disconnect;
    setState(() => status = 'Disconnected');
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

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loadDevices,
              child: const Text('Refresh Printer List'),
            ),
          ],
        ),
      ),
    );
  }
}