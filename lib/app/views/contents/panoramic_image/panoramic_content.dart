part of '../content.dart';

class PanoramicContent extends StatefulWidget {
  final CustomerPlaceContent content;
  const PanoramicContent({super.key, required this.content});

  @override
  State<PanoramicContent> createState() => _PanoramicContentState();
}

class _PanoramicContentState extends State<PanoramicContent> {
  late final VideoPlayerWidgetController? controller;
  late final TemplatePanoramicView template;
  late final List<PropertyLocationItem> locations;
  List<Hotspot> hotspots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    template = widget.content.getTemplate();
    locations = template.locations;
    services.tracking.screen.start();
    cancelAudio();
    _loadHotspots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PanoramaViewer(
            interactive: true,
            sensorControl: SensorControl.absoluteOrientation,
            hotspots: hotspots,
            onImageLoad: _onImageLoad,
            longitude: 15,
            child: Image(image: AppImageProvider(appFile: template.panoramicImage.defaultFile.mediaResource())),
          ),
          if (_isLoading)
            Container(
              height: context.height,
              width: context.width,
              color: AppTheme.light,
              child: Center(child: const CircularProgressIndicator(color: AppTheme.primary500)),
            ),
          if (services.ventour.applicationType != ApplicationType.loan)
            SizedBox(height: kToolbarHeight + 8, child: HeaderWidget()),
          if (services.accessibility.config.enableSignLanguage &&
              template.accessibleInformation.signLanguage.getUuid().isNotEmpty)
            AccessibilityVideoWidget(
              widgetUuid: template.accessibleInformation.signLanguage.getUuid(),
              video: template.accessibleInformation.signLanguage,
              initialPosition: Offset((context.width - 300) / 2, context.height - (context.height * 0.72)),
            ),
        ],
      ),
    );
  }

  List<Hotspot> _loadHotspots() {
    if (locations.isNotEmpty) {
      for (var hotspot in locations) {
        String coordsText = hotspot.coords.mainTranslateRichText();
        if (coordsText.isNotEmpty) {
          var coords = coordsText.split(",");
          hotspots.add(
            Hotspot(
              latitude: double.parse(coords[0]) + 3.2,
              longitude: double.parse(coords[1]) + 0.2,
              name: hotspot.title.translateRichText(),
              width: 24,
              height: 24,
              widget: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.secondary600,
                  borderRadius: BorderRadius.all(Radius.circular(9999)),
                ),
              ),
            ),
          );
        }
      }
    }
    return hotspots;
  }

  void _onImageLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
}
