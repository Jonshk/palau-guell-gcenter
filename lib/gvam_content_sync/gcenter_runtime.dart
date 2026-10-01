class GCenterRuntime {
  static String? _deviceUuid;
  static String? _publicationId;

  static String? get deviceUuid => _deviceUuid;
  static String? get publicationId => _publicationId;

  static bool get isConfigured =>
      (_deviceUuid?.trim().isNotEmpty ?? false);

  static void configure({
    required String deviceUuid,
    String? publicationId,
  }) {
    final id = deviceUuid.trim();
    if (id.isEmpty) {
      throw ArgumentError('deviceUuid no puede estar vacío');
    }

    _deviceUuid = id;
    _publicationId = publicationId?.trim().isEmpty == true
        ? null
        : publicationId?.trim();
  }

  static void updatePublication(String? publicationId) {
    _publicationId = publicationId?.trim().isEmpty == true
        ? null
        : publicationId?.trim();
  }
}
