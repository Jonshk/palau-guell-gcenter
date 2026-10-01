part of '../content.dart';

class PanoramicWebContent extends StatefulWidget {
  final CustomerPlaceContent content;

  const PanoramicWebContent({super.key, required this.content});

  @override
  State<PanoramicWebContent> createState() => _PanoramicWebContentState();
}

class _PanoramicWebContentState extends State<PanoramicWebContent> with TickerProviderStateMixin {
  final String isoCode = services.languages.current.isoCode;
  late final List<PropertyLocationItem> locations;
  late final TemplatePanoramicView template;

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showAnimation = true;

  late AppFile image;
  List<Map<String, dynamic>> hotspots = [];
  double lat = 0.0, lon = 0.0, tilt = 0.0;
  String viewTypeId = "";

  @override
  void initState() {
    template = widget.content.getTemplate();
    services.tracking.screen.start();
    image = template.panoramicImage.defaultFile.mediaResource();
    locations = template.locations;
    cancelAudio();
    _loadPanoramicView();
    _loadListenner();
    _loadAnimation();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadPanoramicView() {
    if (locations.isNotEmpty) {
      var index = 0;
      for (var hotspot in locations) {
        String coordsText = hotspot.coords.mainTranslateRichText();

        if (coordsText.isNotEmpty) {
          var coords = coordsText.split(",");
          hotspots.add({
            'id': hotspot.uuid,
            'pitch': double.parse(coords[0]) + 3.2,
            'yaw': double.parse(coords[1]) + 0.2,
            'imageIndex': index,
            'title': hotspot.title.translateRichText(),
            'description': hotspot.description.translateRichText(),
          });
        }
        index++;
      }
    }
    html.IFrameElement htmlIFrameElement;
    if (kReleaseMode) {
      htmlIFrameElement = html.IFrameElement()..src = 'assets/assets/panoramic/panoramic-web-view.html';
    } else {
      htmlIFrameElement = html.IFrameElement()..src = 'assets/panoramic/panoramic-web-view.html';
    }

    htmlIFrameElement.style.border = 'none';

    String url = (services.downloader.contentsDownloaded)
        ? "data:${image.webFile!.type}/${image.webFile!.extension};base64,${image.webFile!.data}"
        : image.url;

    Logger.log(
      "CONTENT DOWNLOADED ${services.downloader.contentsDownloaded}",
      "_PanoramicWebContentState",
      "_loadPanoramicView",
    );

    htmlIFrameElement.onLoad.listen((_) {
      String jsonHotspots = jsonEncode({'urlPanorama': url, 'hotspots': hotspots});
      if (htmlIFrameElement.contentWindow != null) {
        htmlIFrameElement.contentWindow!.postMessage(jsonHotspots, "*");
      }
    });

    viewTypeId = 'html-element-view-${image.uuid}';
    ui.platformViewRegistry.registerViewFactory(viewTypeId, (int viewId) => htmlIFrameElement);
  }

  void _loadListenner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      html.window.onMessage.listen((event) {
        if (event.data.toString().contains('openLocationModal')) {
          String arguments = event.data.toString().replaceAll('openLocationModal/', '');
          List<dynamic> args = arguments.split('/');
          if (args.isNotEmpty) {
            //TODO:
            // Navigator.push(
            //   context,
            //   PageRouteBuilder(
            //     opaque: false,
            //     pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            //       opacity: animation,
            //       child: ScaleTransition(
            //         scale: animation,
            //         child: Container(),
            //         // child: PointerInterceptor(
            //         //   child: HotspotImageModal(
            //         //     widgetUuid: template.basicInformation.uuid,
            //         //     title: args[0],
            //         //     description: args[1],
            //         //     image: template.locations[int.parse(args[2])].image.mediaResource(mainLanguage: true),
            //         //     isEcclesiastical: args[3] == 'true' ? true : false,
            //         //   ),
            //         // ),
            //       ),
            //     ),
            //   ),
            // );
          }
        }
      });
    });
  }

  void _loadAnimation() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _animation =
        Tween<double>(
          begin: 0.4,
          end: 0.6,
        ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut))..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _animationController.reverse();
          } else if (status == AnimationStatus.dismissed) {
            _animationController.forward();
          }
        });
    _animationController.forward();

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _showAnimation = false;
        });
        _animationController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (services.ventour.applicationType != ApplicationType.loan)
            SizedBox(height: kToolbarHeight + 8, child: HeaderWidget()),
          Expanded(
            child: Stack(
              children: [
                HtmlElementView(viewType: viewTypeId),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _showAnimation ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: _buildAnimatedHand(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHand() {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset((context.width) * _animation.value, context.height * 0.05),
            child: const Icon(Icons.touch_app, size: 64, color: AppTheme.primary500),
          );
        },
      ),
    );
  }
}
