import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../flutter_scandit.dart';
import './models/index.dart';
import './utils/symbology_utils.dart';

typedef ResumeBarcodeScanning = Future Function();

/// Make sure that you display this widghet only after the app was granted the camera
/// permissions from the user. You can use 'permission_handler' package or similar for this
/// matters.
class Scandit extends StatefulWidget {
  static const StandardMessageCodec _decoder = StandardMessageCodec();

  static const List<Symbology> defaultSymbologies = [Symbology.EAN13_UPCA];
  final String licenseKey;
  final List<Symbology> symbologies;
  final void Function(BarcodeResult) scanned;
  final void Function(BarcodeScanException) onError;
  final void Function(ScanditController) onScanditCreated;

  const Scandit({
    Key key,
    @required this.licenseKey,
    @required this.scanned,
    this.onScanditCreated,
    this.onError,
    this.symbologies = defaultSymbologies,
  }) : super(key: key);

  @override
  _ScanditState createState() => _ScanditState();
}

class _ScanditState extends State<Scandit> with WidgetsBindingObserver {
  static const String _licenseKeyField = "licenseKey";
  static const String _symbologiesField = "symbologies";
  static const String _platformViewId = "ScanditPlatformView";
  ScanditController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ScanditController(widget.scanned, widget.onError);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _controller.stopCamera();
    }
    if (state == AppLifecycleState.resumed) {
      _controller.startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = {
      _licenseKeyField: widget.licenseKey,
      _symbologiesField:
          widget.symbologies.map(SymbologyUtils.getSymbologyString).toList()
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: _platformViewId,
        creationParams: arguments,
        creationParamsCodec: Scandit._decoder,
      );
    }

    return UiKitView(
      viewType: _platformViewId,
      creationParams: arguments,
      creationParamsCodec: Scandit._decoder,
      onPlatformViewCreated: (_) => widget.onScanditCreated?.call(_controller),
    );
  }
}
