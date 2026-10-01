part of '../config/utils.dart';

extension AppVideoProvider on AppFile {
  VideoPlayerController getController() {
    if (services.downloader.contentsDownloaded) {
      if (kIsWeb) {
        String url = "data:${webFile!.type}/${webFile!.extension};base64,${webFile!.data}";
        return VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        return VideoPlayerController.file(file!);
      }
    } else if (this.url.isNotEmpty) {
      return VideoPlayerController.networkUrl(Uri.parse(this.url));
    }
    return VideoPlayerController.asset("");
  }
}

