import 'barcode_format.dart';

class Barcode {
  Barcode(
    this.data,
    this.format,
    this.rawBytes,
  );

  final String? data;
  final BarcodeFormat format;
  final List<int>? rawBytes;
}
