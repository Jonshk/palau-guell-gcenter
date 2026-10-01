part of '../config/utils.dart';

class AppImageProvider extends ImageProvider {
  final AppFile appFile;
  final bool tour;

  AppImageProvider({required this.appFile, this.tour = false});

  @override
  ImageStreamCompleter loadImage(Object key, ImageDecoderCallback decode) {
    if (services.downloader.contentsDownloaded && (services.ventour.applicationType == ApplicationType.loan || !tour)) {
      if (kIsWeb) {
        return CachedNetworkImageProvider(
          "data:${appFile.webFile!.type}/${appFile.webFile!.extension};base64,${appFile.webFile!.data}",
        ).resolve(ImageConfiguration(bundle: rootBundle, devicePixelRatio: 1.0)).completer!;
      } else {
        if (appFile.file != null) {
          return FileImage(
            File(appFile.file!.path),
          ).resolve(ImageConfiguration(bundle: rootBundle, devicePixelRatio: 1.0)).completer!;
        }
      }
    } else if (appFile.url.isNotEmpty) {
      return CachedNetworkImageProvider(
        appFile.url,
      ).resolve(ImageConfiguration(bundle: rootBundle, devicePixelRatio: 1.0)).completer!;
    }
    return const AssetImage(
      'assets/img/error-image.png',
    ).resolve(ImageConfiguration(bundle: rootBundle, devicePixelRatio: 1.0)).completer!;
  }

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AppFile>(appFile);
  }
}
