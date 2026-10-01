part of '../config/utils.dart';

extension AppSvgProvider on MediaResourceFile {
  BytesLoader getBytesLoader() {
    late final BytesLoader bytesLoader;
    AppFile appFile = services.pipes.getAppFileFromMediaResource(this);
    if (services.downloader.contentsDownloaded) {
      if (kIsWeb) {
        String url = "data:${appFile.webFile!.type}/${appFile.webFile!.extension};base64,${appFile.webFile!.data}";
        return SvgNetworkLoader(url);
      } else {
        return SvgBytesLoader(appFile.file!.readAsBytesSync());
      }
    } else if (appFile.url.isNotEmpty) {
      bytesLoader = SvgNetworkLoader(appFile.url);
    }
    return bytesLoader;
  }
}
