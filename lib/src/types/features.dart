class SystemFeatures {
  SystemFeatures(
    this.hasFlash,
    this.hasBackCamera,
    this.hasFrontCamera,
  );

  final bool hasFlash;
  final bool hasFrontCamera;
  final bool hasBackCamera;

  factory SystemFeatures.fromJson(Map<String, dynamic> features) =>
      SystemFeatures(
          features['hasFlash'] ?? false,
          features['hasBackCamera'] ?? false,
          features['hasFrontCamera'] ?? false);
}
