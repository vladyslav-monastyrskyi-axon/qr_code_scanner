enum BarcodeFormat {
  aztec,
  codabar,
  code39,
  code93,
  code128,
  dataMatrix,
  ean8,
  ean13,
  itf,
  maxicode,
  pdf417,
  qrcode,
  rss14,
  rssExpanded,
  upcA,
  upcE,
  upcEanExtension,
  unknown,
}

extension BarcodeFormatExtension on BarcodeFormat {
  static BarcodeFormat fromString(String format) {
    switch (format) {
      case 'AZTEC':
        return BarcodeFormat.aztec;
      case 'CODABAR':
        return BarcodeFormat.codabar;
      case 'CODE_39':
        return BarcodeFormat.code39;
      case 'CODE_93':
        return BarcodeFormat.code93;
      case 'CODE_128':
        return BarcodeFormat.code128;
      case 'DATA_MATRIX':
        return BarcodeFormat.dataMatrix;
      case 'EAN_8':
        return BarcodeFormat.ean8;
      case 'EAN_13':
        return BarcodeFormat.ean13;
      case 'ITF':
        return BarcodeFormat.itf;
      case 'MAXICODE':
        return BarcodeFormat.maxicode;
      case 'PDF_417':
        return BarcodeFormat.pdf417;
      case 'QR_CODE':
        return BarcodeFormat.qrcode;
      case 'RSS14':
        return BarcodeFormat.rss14;
      case 'RSS_EXPANDED':
        return BarcodeFormat.rssExpanded;
      case 'UPC_A':
        return BarcodeFormat.upcA;
      case 'UPC_E':
        return BarcodeFormat.upcE;
      case 'UPC_EAN_EXTENSION':
        return BarcodeFormat.upcEanExtension;
      default:
        return BarcodeFormat.unknown;
    }
  }
}
