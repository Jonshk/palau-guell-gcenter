part of '../config/utils.dart';

extension AppJsonProvider on AppFile {
  Future<dynamic> loadJson() async {
    if (services.downloader.contentsDownloaded) {
      if (kIsWeb) {
        final data = webFile!.data;
        final decoded = utf8.decode(base64Decode(data));
        return jsonDecode(decoded);
      } else {
        final bytes = await file!.readAsBytes();
        final text = utf8.decode(bytes);
        return jsonDecode(text);
      }
    } else if (this.url.isNotEmpty) {
      try {
        final response = await Dio().get(this.url);
        if (response.statusCode == 200) {
          if (response.data is Map || response.data is List) {
            return response.data;
          } else {
            return jsonDecode(response.data);
          }
        } else {
          throw Exception('Error al cargar JSON: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error de red: $e');
      }
    }
  }
}
