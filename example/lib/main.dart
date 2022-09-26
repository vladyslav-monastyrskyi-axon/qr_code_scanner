import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(const MaterialApp(home: MyHome()));

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const QRViewExample();
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  Barcode? result;
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();

    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }

    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _buildQrView()),
          if (result != null)
            Text('Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.data}')
          else
            const Text('Scan a code'),
        ],
      ),
    );
  }

  Widget _buildQrView() {
    return QrView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      onPermissionSet: _onPermissionSet,
      overlayOptions: OverlayOptions(
        scanAreaWidth: 240,
        scanAreaHeight: 240,
        scanAreaOffset: 0,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() => this.controller = controller);

    controller.scannedDataStream.listen((scanData) {
      setState(() => result = scanData);
    });
  }

  void _onPermissionSet(QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
