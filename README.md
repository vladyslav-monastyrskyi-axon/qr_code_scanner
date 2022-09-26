# Project in Maintenance Mode Only

Since the underlying frameworks of this package, [zxing for android](https://github.com/zxing/zxing) and [MTBBarcodescanner for iOS](https://github.com/mikebuss/MTBBarcodeScanner) are both not longer maintaned, this plugin is no longer up to date and in maintenance mode only. Only bug fixes and minor enhancements will be considered.

# QR Code Scanner

[![pub package](https://img.shields.io/pub/v/qr_code_scanner?include_prereleases)](https://pub.dartlang.org/packages/qr_code_scanner)
[![Join the chat](https://img.shields.io/discord/829004904600961054)](https://discord.gg/aZujk84f6V)
[![GH Actions](https://github.com/juliuscanute/qr_code_scanner/workflows/dart/badge.svg)](https://github.com/juliuscanute/qr_code_scanner/actions)

A QR code scanner that works on both iOS and Android by natively embedding the platform view within Flutter. The integration with Flutter is seamless, much better than jumping into a native Activity or a ViewController to perform the scan.

## Android Integration
In order to use this plugin, please update the Gradle, Kotlin and Kotlin Gradle Plugin:

In ```android/build.gradle``` change ```ext.kotlin_version = '1.3.50'``` to ```ext.kotlin_version = '1.5.10'```

In ```android/build.gradle``` change ```classpath 'com.android.tools.build:gradle:3.5.0'``` to ```classpath 'com.android.tools.build:gradle:4.2.0'```

In ```android/gradle/wrapper/gradle-wrapper.properties``` change ```distributionUrl=https\://services.gradle.org/distributions/gradle-5.6.2-all.zip``` to ```distributionUrl=https\://services.gradle.org/distributions/gradle-6.9-all.zip```

In ```android/app/build.gradle``` change 
```defaultConfig{```
  ```...```
  ```minSdkVersion 16```
```}``` to 
```defaultConfig{```
  ```...```
  ```minSdkVersion 21```
```}```

### *Warning*
If you are using Flutter Beta or Dev channel (1.25 or 1.26) you can get the following error:

`java.lang.AbstractMethodError: abstract method "void io.flutter.plugin.platform.PlatformView.onFlutterViewAttached(android.view.View)"`

This is a bug in Flutter which is being tracked here: https://github.com/flutter/flutter/issues/72185

There is a workaround by adding `android.enableDexingArtifactTransform=false` to your `gradle.properties` file.

## iOS Integration
In order to use this plugin, add the following to your Info.plist file:
```
<key>io.flutter.embedded_views_preview</key>
<true/>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes</string>
```

## Flip Camera (Back/Front)
The default camera is the back camera.
```dart
await controller.flipCamera();
```

## Flash (Off/On)
By default, flash is OFF.
```dart
await controller.toggleFlash();
```

## Resume/Pause
Pause camera stream and scanner.
```dart
await controller.pauseCamera();
```
Resume camera stream and scanner.
```dart
await controller.resumeCamera();
```


# SDK
Requires at least SDK 21.
Requires at least iOS 8.