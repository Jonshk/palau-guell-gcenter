import '/config.dart';

class TourCard extends StatelessWidget {
  final Tour tour;

  const TourCard({super.key, required this.tour});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => goTour(),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.light,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(offset: Offset(2, 4), blurRadius: 10, color: Colors.black.withAlpha(64))],
        ),
        child: Padding(
          padding: const EdgeInsetsGeometry.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 16,
            children: [
              AspectRatio(
                aspectRatio: 317 / 136,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                  child: Image(
                    image: AppImageProvider(appFile: tour.card.defaultImage.mediaResource(mainLanguage: true)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 13,
                      children: [
                        Text(
                          tour.card.title.translateRichText().toUpperCase(),
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'archivo',
                            color: AppTheme.primary900,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          tour.card.description.translateRichText(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'archivo',
                            color: AppTheme.primary900,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      spacing: 4,
                      children: [
                        Icon(Symbols.schedule, size: 14, color: AppTheme.primary900, weight: 700),
                        Text(
                          _getTourDuration(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'archivo',
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTourDuration() {
    int duration = tour.minutesDuration;
    int hours = duration ~/ 60;
    int minutes = duration % 60;

    String result = "";

    if (hours > 0) {
      result += "$hours h";
    }

    if (minutes > 0) {
      if (result.isNotEmpty) result += " ";
      result += "$minutes min";
    }

    // Si no hay horas ni minutos (0), muestra “0 min” (o puedes cambiarlo)
    return result.isNotEmpty ? result : "0 min";
  }

  void goTour() {
    services.tours.setCurrent(tour);
    if (services.tours.hasAccessibility(tour)) {
      NavigatorExtension.show(
        Get.context!,
        AccesibilityModal(
          onTap: () {
            Navigator.pop(Get.context!);
            _goDownload();
          },
        ),
      );
    } else {
      _goDownload();
    }
  }

  void _goDownload() {
    if (services.ventour.applicationType == ApplicationType.pwa &&
        !services.downloader.status.isDownloaded(tour.uuid)) {
      NavigatorExtension.show(Get.context!, DownloadModal(tour: tour));
    } else {
      services.tracking.creator.tourAccess(tour.uuid, services.tours.current.accessibility);
      Get.toNamed(AppRoutes.tree);
    }
  }
}
