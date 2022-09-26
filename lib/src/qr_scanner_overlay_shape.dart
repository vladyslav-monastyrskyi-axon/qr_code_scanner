import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum BorderCap { square, round }

enum ScanLineAlignment { outside, center, inside }

enum ScanLineCap { square, round }

class OverlayOptions {
  OverlayOptions({
    this.border = const BorderSide(
      width: 6.0,
      strokeAlign: StrokeAlign.center,
      color: Color(0xAF000000),
    ),
    this.borderCap = BorderCap.round,
    this.borderRadius = 12.0,
    this.borderLength = 64.0,
    this.borderEnabled = true,
    this.scanLineWidth = 6.0,
    this.scanLineEndWidth,
    this.scanLineCap = ScanLineCap.round,
    this.scanLineAlignment = ScanLineAlignment.inside,
    this.scanLineColors = const [Colors.white],
    this.scanLineColorStops,
    this.scanLinePosition,
    this.scanLineEnabled = true,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.75),
    this.scanAreaSize,
    this.scanAreaHeight,
    this.scanAreaWidth,
    this.scanAreaOffset,
  });

  final double borderRadius;
  final double borderLength;
  final BorderCap borderCap;
  final BorderSide border;
  final bool borderEnabled;
  final double scanLineWidth;
  final double? scanLineEndWidth;
  final ScanLineCap scanLineCap;
  final ScanLineAlignment scanLineAlignment;
  final List<Color> scanLineColors;
  final List<double>? scanLineColorStops;
  final Offset? scanLinePosition;
  final bool scanLineEnabled;
  final Color overlayColor;
  final double? scanAreaSize;
  final double? scanAreaHeight;
  final double? scanAreaWidth;
  final double? scanAreaOffset;
}

abstract class OverlayShape extends ShapeBorder {
  OverlayShape({
    double? scanAreaSize,
    double? scanAreaHeight,
    double? scanAreaWidth,
    double? scanAreaOffset,
  })  : scanAreaWidth = scanAreaWidth ?? scanAreaSize ?? 0.0,
        scanAreaHeight = scanAreaHeight ?? scanAreaSize ?? 0.0,
        scanAreaOffset = scanAreaOffset ?? 0.0 {
    assert(
      (scanAreaWidth == null && scanAreaHeight == null) || (scanAreaSize == null && scanAreaWidth != null && scanAreaHeight != null),
      'Use only scanAreaWidth and scanAreaHeight or only scanAreaSize',
    );
  }

  final double scanAreaWidth;
  final double scanAreaHeight;
  final double scanAreaOffset;
}

class QrScannerOverlayShape extends OverlayShape {
  QrScannerOverlayShape({
    required this.border,
    required this.borderCap,
    required this.borderRadius,
    required this.borderLength,
    required this.borderEnabled,
    required this.scanLineWidth,
    this.scanLineEndWidth,
    required this.scanLineCap,
    required this.scanLineAlignment,
    required this.scanLineColors,
    this.scanLineColorStops,
    this.scanLinePosition,
    required this.scanLineEnabled,
    required this.overlayColor,
    double? scanAreaSize,
    double? scanAreaHeight,
    double? scanAreaWidth,
    double? scanAreaOffset,
  }) : super(
          scanAreaSize: scanAreaSize,
          scanAreaWidth: scanAreaHeight,
          scanAreaHeight: scanAreaWidth,
          scanAreaOffset: scanAreaOffset,
        );

  final double borderRadius;
  final double borderLength;
  final BorderCap borderCap;
  final BorderSide border;
  final bool borderEnabled;
  final double scanLineWidth;
  final double? scanLineEndWidth;
  final ScanLineCap scanLineCap;
  final ScanLineAlignment scanLineAlignment;
  final List<Color> scanLineColors;
  final List<double>? scanLineColorStops;
  final Offset? scanLinePosition;
  final bool scanLineEnabled;
  final Color overlayColor;

  double get _borderOffset {
    final borderOffset = <StrokeAlign, double>{
      StrokeAlign.outside: -border.width / 2.0,
      StrokeAlign.center: 0.0,
      StrokeAlign.inside: border.width / 2.0,
    };

    return borderOffset[border.strokeAlign] ?? 0.0;
  }

  double get _scanLineOffset {
    final scanLineOffset = <ScanLineAlignment, double>{
      ScanLineAlignment.outside: borderEnabled && border.width > 0.0 ? -_borderOffset + (border.width / 2.0) : 0.0,
      ScanLineAlignment.center: borderEnabled && border.width > 0.0 ? -_borderOffset : 0.0,
      ScanLineAlignment.inside: borderEnabled && border.width > 0.0 ? -_borderOffset - (border.width / 2.0) : 0.0,
    };

    return scanLineOffset[scanLineAlignment] ?? 0.0;
  }

  double get _scanLineRadius {
    final scanLineRadius = <ScanLineCap, double>{
      ScanLineCap.square: 0.0,
      ScanLineCap.round: 1.0,
    };

    return scanLineRadius[scanLineCap] ?? 0.0;
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  QrScannerOverlayShape scale(double t) {
    return QrScannerOverlayShape(
      border: border,
      borderCap: borderCap,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      borderEnabled: borderEnabled,
      scanLineWidth: scanLineWidth * t,
      scanLineEndWidth: scanLineEndWidth,
      scanLineCap: scanLineCap,
      scanLineAlignment: scanLineAlignment,
      scanLineColors: scanLineColors,
      scanLineColorStops: scanLineColorStops,
      scanLinePosition: scanLinePosition,
      scanLineEnabled: scanLineEnabled,
      overlayColor: overlayColor,
      scanAreaHeight: scanAreaHeight * t,
      scanAreaWidth: scanAreaWidth * t,
      scanAreaOffset: scanAreaOffset * t,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final width = rect.width;
    final height = rect.height;
    final scanAreaWidth = this.scanAreaWidth < width ? this.scanAreaWidth : width;
    final scanAreaHeight = this.scanAreaHeight < height ? this.scanAreaHeight : height;

    final roiRect = Rect.fromLTWH(
      rect.left + (width / 2.0) - (scanAreaWidth / 2.0) + _borderOffset,
      rect.top + (height / 2.0) - (scanAreaHeight / 2.0) + _borderOffset - scanAreaOffset,
      scanAreaWidth - _borderOffset,
      scanAreaHeight - _borderOffset,
    );

    double borderLength = this.borderLength;
    final maxBorderLength = min(roiRect.width / 2.0, roiRect.height / 2.0);
    borderLength = (borderLength > maxBorderLength) ? maxBorderLength : borderLength;
    borderLength -= borderCap == BorderCap.round ? (border.width / 2.0) : 0.0;

    // limit border radius
    double borderRadius = this.borderRadius;
    borderRadius = (borderRadius > borderLength) ? borderLength : borderRadius;

    // calculate border properties with alignment
    double responsiveBorderRadius = 0.0;
    double responsiveBorderOffset = 0.0;
    if (border.strokeAlign == StrokeAlign.outside) {
      responsiveBorderOffset = borderRadius + _borderOffset + (borderRadius > 0.0 ? (border.width / 2.0) : 0.0);
      responsiveBorderRadius = borderRadius - _borderOffset;
    } else if (border.strokeAlign == StrokeAlign.center) {
      responsiveBorderOffset = borderRadius + _borderOffset;
      responsiveBorderRadius = borderRadius;
    } else if (border.strokeAlign == StrokeAlign.inside) {
      responsiveBorderOffset = borderRadius + _borderOffset - (border.width / 2.0);
      responsiveBorderRadius = borderRadius - _borderOffset;
    }

    canvas.drawPath(
      Path.combine(
          PathOperation.difference,
          Path()..addRect(rect),
          Path()..addRRect(RRect.fromRectAndRadius(roiRect, Radius.circular(borderRadius)))),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.values[borderCap.index]
      ..strokeWidth = border.width
      ..color = border.color;

    final topLeftBorderPath = _buildTopLeftBorderPath(
      roiRect,
      borderLength,
      responsiveBorderRadius,
      responsiveBorderOffset,
    );

    final topRightBorderPath = _buildTopRightBorderPath(
      roiRect,
      borderLength,
      responsiveBorderRadius,
      responsiveBorderOffset,
    );

    final bottomRightBorderPath = _buildBottomRightBorderPath(
      roiRect,
      borderLength,
      responsiveBorderRadius,
      responsiveBorderOffset,
    );

    final bottomLeftBorderPath = _buildBottomLeftBorderPath(
      roiRect,
      borderLength,
      responsiveBorderRadius,
      responsiveBorderOffset,
    );

    canvas
      ..drawPath(topLeftBorderPath, borderPaint)
      ..drawPath(topRightBorderPath, borderPaint)
      ..drawPath(bottomRightBorderPath, borderPaint)
      ..drawPath(bottomLeftBorderPath, borderPaint);

    if (scanLineEnabled) {
      final scanLineEndWidth = this.scanLineEndWidth ?? scanLineWidth;
      final scanLineLength = (roiRect.width / 2.0) - (scanLineCap == ScanLineCap.round ? scanLineEndWidth / 2.0 : 0.0) + _scanLineOffset;
      final scanLineColorStops = this.scanLineColorStops ??
          [
            for (int i = 0; i < scanLineColors.length; i++)
              i * (1.0 / (scanLineColors.length - 1)),
          ];
      final scanLinePosition = _calculateScanLinePosition(roiRect);

      final scanLinePaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(scanLineLength, 0.0),
          scanLineColors,
          scanLineColorStops,
        )
        ..style = PaintingStyle.fill;

      final scanLinePath = _buildScanLinePath(scanLineLength, scanLineEndWidth);

      canvas.save();
      canvas.translate(
        scanLinePosition.dx,
        scanLinePosition.dy,
      );

      canvas
        ..save()
        ..drawPath(scanLinePath, scanLinePaint)
        ..restore()
        ..rotate(pi)
        ..save()
        ..drawPath(scanLinePath, scanLinePaint)
        ..restore();

      canvas.restore();
    }
  }

  Path _buildTopLeftBorderPath(
    Rect roiRect,
    double borderLength,
    double responsiveBorderRadius,
    double responsiveBorderOffset,
  ) {
    return Path()
      ..moveTo(
        roiRect.left + _borderOffset,
        roiRect.top + borderLength,
      )
      ..lineTo(
        roiRect.left + _borderOffset,
        roiRect.top + responsiveBorderOffset,
      )
      ..arcToPoint(
        Offset(
          roiRect.left + responsiveBorderOffset,
          roiRect.top + _borderOffset,
        ),
        radius: Radius.circular(responsiveBorderRadius),
      )
      ..lineTo(
        roiRect.left + borderLength,
        roiRect.top + _borderOffset,
      );
  }

  Path _buildTopRightBorderPath(
    Rect roiRect,
    double borderLength,
    double responsiveBorderRadius,
    double responsiveBorderOffset,
  ) {
    return Path()
      ..moveTo(
        roiRect.left + roiRect.width - borderLength,
        roiRect.top + _borderOffset,
      )
      ..lineTo(
        roiRect.left + roiRect.width - responsiveBorderOffset,
        roiRect.top + _borderOffset,
      )
      ..arcToPoint(
        Offset(
          roiRect.left + roiRect.width - _borderOffset,
          roiRect.top + responsiveBorderOffset,
        ),
        radius: Radius.circular(responsiveBorderRadius),
      )
      ..lineTo(
        roiRect.left + roiRect.width - _borderOffset,
        roiRect.top + borderLength,
      );
  }

  Path _buildBottomRightBorderPath(
    Rect roiRect,
    double borderLength,
    double responsiveBorderRadius,
    double responsiveBorderOffset,
  ) {
    return Path()
      ..moveTo(
        roiRect.left + roiRect.width - _borderOffset,
        roiRect.top + roiRect.height - borderLength,
      )
      ..lineTo(
        roiRect.left + roiRect.width - _borderOffset,
        roiRect.top + roiRect.height - responsiveBorderOffset,
      )
      ..arcToPoint(
        Offset(
          roiRect.left + roiRect.width - responsiveBorderOffset,
          roiRect.top + roiRect.height - _borderOffset,
        ),
        radius: Radius.circular(responsiveBorderRadius),
      )
      ..lineTo(
        roiRect.left + roiRect.width - borderLength,
        roiRect.top + roiRect.height - _borderOffset,
      );
  }

  Path _buildBottomLeftBorderPath(
    Rect roiRect,
    double borderLength,
    double responsiveBorderRadius,
    double responsiveBorderOffset,
  ) {
    return Path()
      ..moveTo(
        roiRect.left + borderLength,
        roiRect.top + roiRect.height - _borderOffset,
      )
      ..lineTo(
        roiRect.left + responsiveBorderOffset,
        roiRect.top + roiRect.height - _borderOffset,
      )
      ..arcToPoint(
        Offset(
          roiRect.left + _borderOffset,
          roiRect.top + roiRect.height - responsiveBorderOffset,
        ),
        radius: Radius.circular(responsiveBorderRadius),
      )
      ..lineTo(
        roiRect.left + _borderOffset,
        roiRect.top + roiRect.height - borderLength,
      );
  }

  Path _buildScanLinePath(
    double scanLineLength,
    double scanLineEndWidth,
  ) {
    return Path()
      ..moveTo(
        0.0,
        -scanLineWidth / 2.0,
      )
      ..lineTo(
        scanLineLength,
        -scanLineEndWidth / 2.0,
      )
      ..arcToPoint(
        Offset(
          scanLineLength,
          scanLineEndWidth / 2.0,
        ),
        radius: Radius.circular(_scanLineRadius),
      )
      ..lineTo(
        0.0,
        scanLineWidth / 2.0,
      )
      ..close();
  }

  Offset _calculateScanLinePosition(Rect roiRect) {
    final centerX = roiRect.left + roiRect.width / 2.0;
    final centerY = roiRect.top + roiRect.height / 2.0;
    final maxScanLineWidth = max(scanLineWidth, scanLineEndWidth ?? 0.0);

    return Offset(
      centerX,
      centerY +
          ((roiRect.height -
                  (roiRect.height / 2.0) -
                  (maxScanLineWidth / 2.0) +
                  _scanLineOffset) *
              (scanLinePosition?.dy ?? 0.0)),
    );
  }
}
