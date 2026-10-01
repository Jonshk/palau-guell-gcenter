import '/config.dart';
import '/resources/utils/html.dart' if (dart.library.js) 'dart:html' as html;
import '/resources/utils/html.dart' if (dart.library.js) 'dart:ui_web' as ui;

class PanoramicVideoWeb extends StatefulWidget {
  final TemplatePanoramicVideo template;

  const PanoramicVideoWeb({super.key, required this.template});

  @override
  State<PanoramicVideoWeb> createState() => _PanoramicVideoWebState();
}

class _PanoramicVideoWebState extends State<PanoramicVideoWeb> {
  late AppFile appFile;
  bool fullScreen = false;
  String viewTypeId = "";

  @override
  void initState() {
    appFile = widget.template.panoramicVideo.video.mediaResource();
    _loadPanoramicView();
    _loadListener();
    cancelAudio();
    super.initState();
  }

  void _loadPanoramicView() {
    String url = services.downloader.contentsDownloaded
        ? "data:${appFile.webFile!.type}/${appFile.webFile!.extension};base64,${appFile.webFile!.data}"
        : appFile.url;

    final html.IFrameElement htmlIFrameElement = html.IFrameElement()
      ..src = 'assets/assets/panoramic/panoramic-video-360.html'
      ..style.border = 'none';

    htmlIFrameElement.onLoad.listen((_) {
      String jsonHotspots = jsonEncode({'urlPanorama': url});
      htmlIFrameElement.contentWindow?.postMessage(jsonHotspots, "*");
    });

    viewTypeId = 'html-element-view-${appFile.uuid}';

    ui.platformViewRegistry.registerViewFactory(viewTypeId, (int viewId) => htmlIFrameElement);
  }

  void _loadListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      html.window.onMessage.listen((event) {
        String action = event.data.toString();
        switch (action) {
          case "stop":
            services.tracking.creator.playerMedia(appFile.uuid, TrackingAction.stop);
          case "play":
            services.tracking.creator.playerMedia(appFile.uuid, TrackingAction.play);
          case "pause":
            services.tracking.creator.playerMedia(appFile.uuid, TrackingAction.pause);
          case "fullScreen":
            {
              services.tracking.creator.fullscreenMode(widget.template.panoramicVideo.uuid);
              setState(() {
                if (fullScreen) {
                  setState(() {
                    fullScreen = false;
                  });
                } else {
                  setState(() {
                    fullScreen = true;
                  });
                }
              });
            }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top, child: const HeaderWidget()),
          if (!fullScreen)
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.5,
              child: HtmlElementView(viewType: viewTypeId),
            )
          else
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height - ((kToolbarHeight + MediaQuery.of(context).padding.top)),
              child: HtmlElementView(viewType: viewTypeId),
            ),
          if (!fullScreen) Padding(padding: EdgeInsetsGeometry.all(16), child: Toolbar()),
          if (!fullScreen)
            TextWidget(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              uuid: widget.template.basicInformation.uuid,
              text: widget.template.basicInformation.paragraph?.translateRichText() ?? "",
            ),
        ],
      ),
    );
  }
}
