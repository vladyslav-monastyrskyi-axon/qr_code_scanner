part of 'qr_view.dart';

class QRViewController {
  QRViewController._(
    MethodChannel channel,
    GlobalKey? qrKey,
    PermissionSetCallback? onPermissionSet,
    CameraFacing cameraFacing,
  )   : _channel = channel,
        _cameraFacing = cameraFacing {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDetect':
          if (call.arguments != null) {
            final args = call.arguments as Map;
            final code = args['code'] as String?;
            final rawType = args['type'] as String;
            final rawBytes = args['rawBytes'] as List<int>?;
            final format = BarcodeFormatExtension.fromString(rawType);

            if (format != BarcodeFormat.unknown) {
              final barcode = Barcode(code, format, rawBytes);
              _scanUpdateController.sink.add(barcode);
            } else {
              _scanUpdateController.sink.add(null);
            }
          }
          break;
        case 'onPermissionSet':
          if (call.arguments != null && call.arguments is bool) {
            _hasPermissions = call.arguments;

            onPermissionSet?.call(this, _hasPermissions);
          }
          break;
      }
    });
  }

  final MethodChannel _channel;
  final CameraFacing _cameraFacing;
  final StreamController<Barcode?> _scanUpdateController = StreamController<Barcode>();

  bool _hasPermissions = false;

  Stream<Barcode?> get scannedDataStream => _scanUpdateController.stream;

  bool get hasPermissions => _hasPermissions;

  Future<void> _startScan(
    GlobalKey key,
    List<BarcodeFormat>? barcodeFormats,
    OverlayShape overlay,
  ) async {
    try {
      await QRViewController.updateDimensions(key, _channel, overlay: overlay);
      return await _channel.invokeMethod('startScan', barcodeFormats?.map((format) => format.index).toList() ?? []);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<CameraFacing> getCameraInfo() async {
    try {
      final cameraFacing = await _channel.invokeMethod('getCameraInfo') as int;

      if (cameraFacing == -1) return _cameraFacing;

      return CameraFacing.values[await _channel.invokeMethod('getCameraInfo') as int];
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<CameraFacing> flipCamera() async {
    try {
      return CameraFacing.values[await _channel.invokeMethod('flipCamera') as int];
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<bool?> getFlashStatus() async {
    try {
      return await _channel.invokeMethod('getFlashInfo');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> toggleFlash() async {
    try {
      await _channel.invokeMethod('toggleFlash') as bool?;
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> pauseCamera() async {
    try {
      await _channel.invokeMethod('pauseCamera');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> stopCamera() async {
    try {
      await _channel.invokeMethod('stopCamera');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<void> resumeCamera() async {
    try {
      await _channel.invokeMethod('resumeCamera');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  Future<SystemFeatures> getSystemFeatures() async {
    try {
      final features = await _channel.invokeMapMethod<String, dynamic>('getSystemFeatures');

      if (features != null) {
        return SystemFeatures.fromJson(features);
      }

      throw CameraException('Error', 'Could not get system features');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  void dispose() {
    if (defaultTargetPlatform == TargetPlatform.iOS) stopCamera();
    _scanUpdateController.close();
  }

  static Future<bool> updateDimensions(
    GlobalKey key,
    MethodChannel channel, {
    required OverlayShape overlay,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (key.currentContext == null) return false;

      SchedulerBinding.instance.addPostFrameCallback((_) async {
        final renderBox = key.currentContext?.findRenderObject() as RenderBox;

        try {
          await channel.invokeMethod(
            'setDimensions',
            {
              'width': renderBox.size.width,
              'height': renderBox.size.height,
              'scanAreaWidth': overlay.scanAreaWidth,
              'scanAreaHeight': overlay.scanAreaHeight,
              'scanAreaOffset': overlay.scanAreaOffset,
            },
          );
        } on PlatformException catch (e) {
          throw CameraException(e.code, e.message);
        }
      });

      return true;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await channel.invokeMethod(
        'changeScanArea',
        {
          'scanAreaWidth': overlay.scanAreaWidth,
          'scanAreaHeight': overlay.scanAreaHeight,
          'scanAreaOffset': overlay.scanAreaOffset,
        },
      );

      return true;
    }

    return false;
  }

  Future<void> scanInvert(bool isScanInvert) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod('invertScan', {'isInvertScan': isScanInvert});
      } on PlatformException catch (e) {
        throw CameraException(e.code, e.message);
      }
    }
  }
}
