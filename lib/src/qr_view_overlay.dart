import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum BorderCap { square, round }

enum ScanLineAlignment { outside, center, inside }

enum ScanLineCap { square, round }

class OverlayOptions {
  OverlayOptions({
    this.border = const BorderSide(
      strokeAlign: BorderSide.strokeAlignCenter,
      color: Colors.white,
      width: 8.0,
    ),
    this.borderCap = BorderCap.round,
    this.borderRadius = 16.0,
    this.borderLength = 64.0,
    this.borderEnabled = true,
    this.scanLineWidth = 2.0,
    this.scanLineEndWidth,
    this.scanLineCap = ScanLineCap.round,
    this.scanLineAlignment = ScanLineAlignment.inside,
    this.scanLineColors = const [Colors.white],
    this.scanLineColorStops,
    this.scanLinePosition,
    this.scanLineEnabled = false,
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

class QrViewOverlayShape extends OverlayShape {
  QrViewOverlayShape({
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
    if (border.strokeAlign == BorderSide.strokeAlignInside) {
      return border.width / 2.0;
    } else if (border.strokeAlign == BorderSide.strokeAlignCenter) {
      return 0.0;
    } else {
      return -border.width / 2.0;
    }
  }

  double get _scanLineOffset {
    switch (scanLineAlignment) {
      case ScanLineAlignment.inside:
        return borderEnabled && border.width > 0.0 ? -_borderOffset - (border.width / 2.0) : 0.0;
      case ScanLineAlignment.center:
        return borderEnabled && border.width > 0.0 ? -_borderOffset : 0.0;
      case ScanLineAlignment.outside:
        return borderEnabled && border.width > 0.0 ? -_borderOffset + (border.width / 2.0) : 0.0;
    }
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
  QrViewOverlayShape scale(double t) {
    return QrViewOverlayShape(
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
      rect.left + (width / 2.0) - (scanAreaWidth / 2.0),
      rect.top + (height / 2.0) - (scanAreaHeight / 2.0) - scanAreaOffset,
      scanAreaWidth,
      scanAreaHeight,
    );

    if (!borderEnabled) {
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(rect),
          Path()..addRRect(RRect.fromRectAndRadius(roiRect, Radius.circular(borderRadius))),
        ),
        backgroundPaint,
      );
    }

    if (borderEnabled) {
      double borderLength = this.borderLength;
      final maxBorderLength = min(roiRect.width / 2.0, roiRect.height / 2.0);
      borderLength = (borderLength < maxBorderLength) ? borderLength : maxBorderLength;

      // limit border radius
      double borderRadius = this.borderRadius;
      borderRadius = (borderRadius < borderLength) ? borderRadius : borderLength;

      // calculate border properties with alignment
      double borderOffset = 0.0;
      if (border.strokeAlign == BorderSide.strokeAlignInside) {
        borderOffset = borderRadius + _borderOffset - (border.width / 2.0);
      } else if (border.strokeAlign == BorderSide.strokeAlignCenter) {
        borderOffset = borderRadius + _borderOffset;
      } else {
        borderOffset = borderRadius + _borderOffset + (borderRadius > 0.0 ? (border.width / 2.0) : 0.0);
      }

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = (borderRadius > 0.0 && borderRadius >= _borderOffset) ? StrokeJoin.round : StrokeJoin.miter
        ..strokeCap = StrokeCap.values[borderCap.index]
        ..strokeWidth = border.width
        ..color = border.color;

      final topLeftBorderPath = _buildTopLeftBorderPath(
        roiRect,
        borderLength,
        borderRadius,
        borderOffset,
      );

      final topRightBorderPath = _buildTopRightBorderPath(
        roiRect,
        borderLength,
        borderRadius,
        borderOffset,
      );

      final bottomRightBorderPath = _buildBottomRightBorderPath(
        roiRect,
        borderLength,
        borderRadius,
        borderOffset,
      );

      final bottomLeftBorderPath = _buildBottomLeftBorderPath(
        roiRect,
        borderLength,
        borderRadius,
        borderOffset,
      );

      canvas
        ..drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect),
            Path()..addRRect(RRect.fromRectAndRadius(roiRect, Radius.circular(borderRadius))),
          ),
          backgroundPaint,
        )
        ..drawPath(topLeftBorderPath, borderPaint)
        ..drawPath(topRightBorderPath, borderPaint)
        ..drawPath(bottomRightBorderPath, borderPaint)
        ..drawPath(bottomLeftBorderPath, borderPaint);
    }

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
    double borderRadius,
    double borderOffset,
  ) {
    return Path()
      ..moveTo(
        roiRect.left + _borderOffset,
        roiRect.top + borderLength,
      )
      ..lineTo(
        roiRect.left + _borderOffset,
        roiRect.top + borderOffset,
      )
      ..arcToPoint(
        Offset(
          roiRect.left + borderOffset,
          roiRect.top + _borderOffset,
        ),
        radius: Radius.circular(borderRadius - _borderOffset),
      )
      ..lineTo(
        roiRect.left + borderLength,
        roiRect.top + _borderOffset,
      );
  }

  Path _buildTopRightBorderPath(
    Rect roiRect,
    double borderLength,
    double borderRadius,
    double borderOffset,
  ) {
    return Path()
      ..moveTo(
        roiRect.left + roiRect.width - borderLength,
        roiRect.top + _borderOffset,
      )
      ..lineTo(
        roiRect.left + roiRect.width - borderOffset,
        roiRect.top + _borderOffset,
      )
      ..arcToPoint(
        Offset(
          roiRect.left + roiRect.width - _borderOffset,
          roiRect.top + borderOffset,
        ),
        radius: Radius.circular(borderRadius - _borderOffset),
      )
      ..lineTo(
        roiRect.left + roiRect.width - _borderOffset,
        roiRect.top + borderLength,
      );
  }

  Path _buildBottomRightBorderPath(
    Rect roiRect,
    double borderLength,
    double borderRadius,
    double borderOffset,
  ) {
    return Path()
      ..moveTo(
        roiRect.left + roiRect.width - _borderOffset,
        roiRect.top + roiRect.height - borderLength,
      )
      ..lineTo(
        roiRect.left + roiRect.width - _borderOffset,
        roiRect.top + roiRect.height - borderOffset,
      )
      ..arcToPoint(
        Offset(
          roiRect.left + roiRect.width - borderOffset,
          roiRect.top + roiRect.height - _borderOffset,
        ),
        radius: Radius.circular(borderRadius - _borderOffset),
      )
      ..lineTo(
        roiRect.left + roiRect.width - borderLength,
        roiRect.top + roiRect.height - _borderOffset,
      );
  }

  Path _buildBottomLeftBorderPath(
    Rect roiRect,
    double borderLength,
    double borderRadius,
    double borderOffset,
  ) {
    return Path()
      ..moveTo(
        roiRect.left + borderLength,
        roiRect.top + roiRect.height - _borderOffset,
      )
      ..lineTo(
        roiRect.left + borderOffset,
        roiRect.top + roiRect.height - _borderOffset,
      )
      ..arcToPoint(
        Offset(
          roiRect.left + _borderOffset,
          roiRect.top + roiRect.height - borderOffset,
        ),
        radius: Radius.circular(borderRadius - _borderOffset),
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
      centerY + ((roiRect.height - (roiRect.height / 2.0) - (maxScanLineWidth / 2.0) + _scanLineOffset) * (scanLinePosition?.dy ?? 0.0)),
    );
  }
}
