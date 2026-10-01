import '/config.dart';
import '/resources/utils/html.dart' if (dart.library.js) 'dart:html' as html;
import '/resources/utils/html.dart' if (dart.library.js) 'dart:ui_web' as ui;

part 'carousel/carousel_content.dart';
part 'image/image_content.dart';
part 'mastersync/mastersync_content.dart';
part 'panoramic_image/panoramic_content.dart';
part 'panoramic_image/panoramic_web_content.dart';
part 'panoramic_video/panoramic_video.dart';
part 'video/video_content.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  @override
  void dispose() {
    audio.sensor.dispose();
    cancelAudio();
    services.navigation.addTrackingContentViewed(services.contents.current.uuid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary100,
      body: PageView.builder(
        controller: services.navigation.contentPageViewCtrl,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.availableContents.length,
        itemBuilder: (_, index) => navigateToContent(services.availableContents[index]),
      ),
    );
  }

  Widget navigateToContent(CustomerPlaceContent content) {
    switch (content.templateKey) {
      case TemplateKeys.carousel_images_template:
        services.tracking.screen.start();
        return CarouselContent(content: content);
      case TemplateKeys.single_image_template:
        services.tracking.screen.start();
        return ImageContent(content: content);
      case TemplateKeys.video_template:
        services.tracking.screen.start();
        return VideoContent(content: content);
      case TemplateKeys.panoramic_video_template:
        services.tracking.screen.start();
        if (kIsWeb) {
          return PanoramicVideoWeb(template: content.getTemplate());
        } else {
          return PanoramicVideo(content: content);
        }
      case TemplateKeys.panoramic_view_template:
        if (kIsWeb) {
          return PanoramicWebContent(content: content);
        } else {
          return PanoramicContent(content: content);
        }
      default:
        return Container();
    }
  }
}
