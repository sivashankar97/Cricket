import 'dart:async';

import 'package:flutter/material.dart';

class Barcode {
  const Barcode(this.code);

  final String? code;
}

class QRViewController {
  final StreamController<Barcode> _controller = StreamController<Barcode>();

  Stream<Barcode> get scannedDataStream => _controller.stream;

  Future<void> toggleFlash() async {}

  Future<bool?> getFlashStatus() async => false;

  void dispose() {
    _controller.close();
  }
}

class QrScannerOverlayShape {
  const QrScannerOverlayShape({
    this.cutOutSize,
    this.borderColor = Colors.transparent,
  });

  final double? cutOutSize;
  final Color borderColor;
}

class QRView extends StatelessWidget {
  const QRView({
    required Key key,
    required this.onQRViewCreated,
    this.overlay,
  }) : super(key: key);

  final void Function(QRViewController) onQRViewCreated;
  final QrScannerOverlayShape? overlay;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'QR scanning is available in the iOS and Android apps.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
