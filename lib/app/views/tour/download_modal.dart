import '/config.dart';

class DownloadModal extends StatefulWidget {
  final Tour tour;
  const DownloadModal({super.key, required this.tour});

  @override
  State<DownloadModal> createState() => _DownloadModalState();
}

class _DownloadModalState extends State<DownloadModal> {
  DownloadedTourStatus tourStatus = DownloadedTourStatus.empty();
  late StreamSubscription<DownloadedLanguageStatus> onLanguageChanged;
  late StreamSubscription<double> currentProgress;
  bool accessibilityEnabled = false;
  bool downloading = false;
  double progress = 0;
  int total = 0;
  double totalSize = 0.0;

  @override
  void initState() {
    tourStatus = services.downloader.status.downloadedLanguageStatus.tourStatus.firstWhere(
      (status) => status.tourUuid == widget.tour.uuid,
      orElse: () => DownloadedTourStatus.empty(),
    );
    accessibilityEnabled = services.accessibility.isEnabled();
    _onDownloadedLanguageStatudChanged();
    _updateProgress();
    _setTotalSize();
    super.initState();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    currentProgress.cancel();
    onLanguageChanged.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          decoration: BoxDecoration(color: AppTheme.light, borderRadius: BorderRadiusGeometry.circular(4)),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_getSituationDownload() == Download.downloaded || _getSituationDownload() != Download.downloading)
                      Text(
                        "i18n.download.title".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          height: 1.4,
                          color: AppTheme.dark
                        ),
                      ),
                      const SizedBox(height: 8,),
                      if (_getSituationDownload() == Download.downloaded || _getSituationDownload() != Download.downloading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          "i18n.download.description".tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 18,
                            height: 1.4,
                            color: AppTheme.dark,
                          ),
                        ),
                      ),
                      if (_getSituationDownload() != Download.downloaded)
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 14,
                              height: 1.5,
                              color: AppTheme.dark,
                            ),
                            children: [
                              TextSpan(text: 'i18n.download.size'.tr),
                              TextSpan(
                                text: "\n${formatBytes(totalSize.toInt())}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          "i18n.download.success".tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 14,
                            height: 1.5,
                           // color: AppTheme.success,
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (_getSituationDownload() == Download.noDownload)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 16,
                          children: [
                            ElevatedButton(
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(4))),
                                fixedSize: WidgetStatePropertyAll(Size.fromHeight(56)),
                                backgroundColor: WidgetStatePropertyAll(AppTheme.primary800)
                              ),
                              onPressed: _download,
                              child: Text(
                                "i18n.download.download".tr,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.light,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ButtonStyle(
                                elevation: WidgetStatePropertyAll(0),
                                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                                backgroundColor: WidgetStatePropertyAll(AppTheme.light),
                                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(4))),
                                fixedSize: WidgetStatePropertyAll(Size.fromHeight(56))
                              ),
                              onPressed: _continue,
                              child: Text(
                                "i18n.download.online".tr,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.dark,
                                  decoration: TextDecoration.underline
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_getSituationDownload() == Download.downloading)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Text(
                              "i18n.download.downloading".tr,
                              style: TextStyle(
                               /// color: AppTheme.light2,
                                fontSize: 10,
                                height: 1.08,
                                letterSpacing: -0.03 * 10,
                              ),
                            ),
                            LinearProgressIndicator(
                              minHeight: 4,
                              backgroundColor: Color(0xFFD3D4D5),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.dark),
                              value: progress,
                            ),
                            Text(
                              "${(progress * 100).toPrecision(3)} %",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.5
                              ),
                            )
                          ],
                        ),
                      if (_getSituationDownload() == Download.downloaded)
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 20),
                          width: context.width,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () => _continue(),
                            child: Text(
                              "i18n.accept".tr.toUpperCase(),
                              style: const TextStyle(color: AppTheme.light, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_getSituationDownload() != Download.downloading) _closeButton(),
            ],
          ),
        ),
      ),
    );
  }

  void _download() {
    setState(() {
      services.downloader.download(tourStatus, accessibilityEnabled);
      downloading = true;
    });
  }

  void _continue() {
    services.tracking.creator.tourAccess(widget.tour.uuid, services.tours.current.accessibility);

    Get.offNamed(AppRoutes.tree);
    
  }

  Widget _closeButton() {
    return Positioned(
      top: 4,
      right: 4,
      child: IconButton(constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 32,)),
    );
  }

  void _onDownloadedLanguageStatudChanged() {
    onLanguageChanged = services.downloader.status.onDownloadedLanguageStatudChanged.stream.listen((
      downloadedLanguage,
    ) {
      var tourStatusUpdated = downloadedLanguage.tourStatus.firstWhere(
        (tourStatusUpdated) => tourStatusUpdated.tourUuid == widget.tour.uuid,
      );
      if (tourStatusUpdated.tourStatus.size > 0) {
        setState(() {
          tourStatus = tourStatusUpdated;
          _setTotalSize();
        });
      }
    });
  }

  void _setTotalSize() {
    setState(() {
      total = tourStatus.tourStatus.size;
      if (accessibilityEnabled) {
        total += tourStatus.accessibilityStatus?.size ?? 0;
      }
      totalSize = total.toDouble();
    });
  }

  void _updateProgress() {
    currentProgress = services.downloader.progress.stream.listen((updatedProgress) {
      setState(() {
        progress = updatedProgress;
        totalSize = total * (1 - progress);
      });
      if (progress == 1) {
        _continue();
      }
    });
  }

  Download _getSituationDownload() {
    if (!services.downloader.status.isDownloaded(widget.tour.uuid) && !downloading) {
      return Download.noDownload;
    } else if (downloading && progress < 1) {
      return Download.downloading;
    } else {
      return Download.downloaded;
    }
  }
}

enum Download { noDownload, downloading, downloaded }
