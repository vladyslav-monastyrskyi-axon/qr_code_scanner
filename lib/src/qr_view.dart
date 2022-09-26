import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'lifecycle_event_handler.dart';
import 'qr_scanner_overlay_shape.dart';
import 'types/barcode.dart';
import 'types/barcode_format.dart';
import 'types/camera.dart';
import 'types/camera_exception.dart';
import 'types/features.dart';
import 'utils/sine_curve.dart';

part 'qr_view_controller.dart';

typedef QRViewCreatedCallback = void Function(QRViewController);
typedef PermissionSetCallback = void Function(QRViewController, bool);

class QrView extends StatefulWidget {
  const QrView({
    required Key key,
    required this.onQRViewCreated,
    this.onPermissionSet,
    this.formatsAllowed = const <BarcodeFormat>[],
    this.cameraFacing = CameraFacing.back,
    required this.overlayOptions,
  }) : super(key: key);

  final QRViewCreatedCallback onQRViewCreated;
  final PermissionSetCallback? onPermissionSet;
  final List<BarcodeFormat> formatsAllowed;
  final CameraFacing cameraFacing;
  final OverlayOptions overlayOptions;

  @override
  State<StatefulWidget> createState() => _QrViewState();
}

class _QrViewState extends State<QrView> with SingleTickerProviderStateMixin {
  final ValueNotifier<Offset> _scanLinePositionNotifier = ValueNotifier(Offset.zero);

  late final AnimationController _scanLineController;
  late final Animation<Offset> _scanLinePosition;

  late final MethodChannel _methodChannel;
  late final LifecycleEventHandler _lifecycleEventHandler;

  late OverlayShape _overlay;

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )
      ..addListener(() => _scanLinePositionNotifier.value = _scanLinePosition.value)
      ..repeat();

    _scanLinePosition = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 1.0),
    ).animate(
      CurvedAnimation(
        parent: _scanLineController,
        curve: const SineCurve(),
      ),
    );

    _overlay = QrScannerOverlayShape(
      border: widget.overlayOptions.border,
      borderCap: widget.overlayOptions.borderCap,
      borderRadius: widget.overlayOptions.borderRadius,
      borderLength: widget.overlayOptions.borderLength,
      borderEnabled: widget.overlayOptions.borderEnabled,
      scanLineWidth: widget.overlayOptions.scanLineWidth,
      scanLineEndWidth: widget.overlayOptions.scanLineEndWidth,
      scanLineCap: widget.overlayOptions.scanLineCap,
      scanLineAlignment: widget.overlayOptions.scanLineAlignment,
      scanLineColors: widget.overlayOptions.scanLineColors,
      scanLineColorStops: widget.overlayOptions.scanLineColorStops,
      scanLineEnabled: widget.overlayOptions.scanLineEnabled,
      overlayColor: widget.overlayOptions.overlayColor,
      scanAreaSize: widget.overlayOptions.scanAreaSize,
      scanAreaHeight: widget.overlayOptions.scanAreaHeight,
      scanAreaWidth: widget.overlayOptions.scanAreaWidth,
      scanAreaOffset: widget.overlayOptions.scanAreaOffset,
    );

    _lifecycleEventHandler = LifecycleEventHandler(resumeCallBack: _updateDimensions);

    WidgetsBinding.instance.addObserver(_lifecycleEventHandler);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (_) {
        _updateDimensions();
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Stack(
          children: [
            _getPlatformQrView(),
            ValueListenableBuilder<Offset>(
              valueListenable: _scanLinePositionNotifier,
              builder: (_, scanLinePosition, __) {
                return Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      border: widget.overlayOptions.border,
                      borderCap: widget.overlayOptions.borderCap,
                      borderRadius: widget.overlayOptions.borderRadius,
                      borderLength: widget.overlayOptions.borderLength,
                      borderEnabled: widget.overlayOptions.borderEnabled,
                      scanLineWidth: widget.overlayOptions.scanLineWidth,
                      scanLineEndWidth: widget.overlayOptions.scanLineEndWidth,
                      scanLineCap: widget.overlayOptions.scanLineCap,
                      scanLineAlignment: widget.overlayOptions.scanLineAlignment,
                      scanLineColors: widget.overlayOptions.scanLineColors,
                      scanLineColorStops: widget.overlayOptions.scanLineColorStops,
                      scanLinePosition: scanLinePosition,
                      scanLineEnabled: widget.overlayOptions.scanLineEnabled,
                      overlayColor: widget.overlayOptions.overlayColor,
                      scanAreaSize: widget.overlayOptions.scanAreaSize,
                      scanAreaHeight: widget.overlayOptions.scanAreaHeight,
                      scanAreaWidth: widget.overlayOptions.scanAreaWidth,
                      scanAreaOffset: widget.overlayOptions.scanAreaOffset,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleEventHandler);

    _scanLinePositionNotifier.dispose();
    _scanLineController.dispose();

    super.dispose();
  }

  Future<void> _updateDimensions() async {
    await QRViewController.updateDimensions(
      widget.key as GlobalKey<State<StatefulWidget>>,
      _methodChannel,
      overlay: _overlay,
    );
  }

  Widget _getPlatformQrView() {
    Widget view;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        view = AndroidView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: _QrCameraSettings(cameraFacing: widget.cameraFacing).toMap(),
          creationParamsCodec: const StandardMessageCodec(),
        );
        break;
      case TargetPlatform.iOS:
        view = UiKitView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: _QrCameraSettings(cameraFacing: widget.cameraFacing).toMap(),
          creationParamsCodec: const StandardMessageCodec(),
        );
        break;
      default:
        throw UnsupportedError("Trying to use the default qrview implementation for $defaultTargetPlatform but there isn't a default one");
    }

    return view;
  }

  void _onPlatformViewCreated(int id) {
    _methodChannel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id');

    final controller = QRViewController._(
      _methodChannel,
      widget.key as GlobalKey<State<StatefulWidget>>?,
      widget.onPermissionSet,
      widget.cameraFacing,
    ).._startScan(
        widget.key as GlobalKey<State<StatefulWidget>>,
        widget.formatsAllowed,
        _overlay,
      );

    widget.onQRViewCreated(controller);
  }
}

class _QrCameraSettings {
  _QrCameraSettings({this.cameraFacing = CameraFacing.unknown});

  final CameraFacing cameraFacing;

  Map<String, dynamic> toMap() {
    return {'cameraFacing': cameraFacing.index};
  }
}
