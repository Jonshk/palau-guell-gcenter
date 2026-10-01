import '/config.dart';

class CustomBeacon {
  final String namespace;
  final int type;
  final int id;

  CustomBeacon({required this.namespace, required this.type, required this.id});
}

CustomBeacon? decodeEddystone(ByteData rawData) {
  try {
    final data = rawData.buffer.asUint8List();

    final parts = _parseHexUID(data);

    return CustomBeacon(
      namespace: _hexToValue(parts[0], false) as String,
      type: _hexToValue(parts[1], true) as int,
      id: _hexToValue(parts[2], true) as int,
    );
  } catch (e) {
    return null;
  }
}

String _bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}

List<String> _parseHexUID(Uint8List data) {
  final truncate = data.sublist(2, 18);
  final hexString = _bytesToHex(truncate);

  return [hexString.substring(0, 20), hexString.substring(20, 24), hexString.substring(24, 32)];
}

dynamic _hexToValue(String hex, bool isNumber) {
  if (hex.length % 2 != 0) {
    debugPrint("Hex length must be even");
    return "";
  }

  final bytes = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }

  if (isNumber) {
    return int.parse(hex, radix: 16);
  } else {
    return utf8.decode(bytes);
  }
}
