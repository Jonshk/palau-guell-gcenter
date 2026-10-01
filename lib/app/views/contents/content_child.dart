import '/config.dart';

class ContentChildView extends StatefulWidget {
  const ContentChildView({super.key});

  @override
  State<ContentChildView> createState() => _ContentChildViewState();
}

class _ContentChildViewState extends State<ContentChildView> {
  @override
  void dispose() {
    audio.sensor.dispose();
    cancelAudio();
    services.navigation.addTrackingContentViewed(services.contents.current.uuid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.primary100, body: navigateToContent(services.contents.current));
  }

  Widget navigateToContent(CustomerPlaceContent content) {
    switch (content.templateKey) {
      case TemplateKeys.carousel_images_template:
        services.tracking.screen.start();
        if (content.categories.any((c) => c.code == AppConstants.masterSync)) {
          return MastersyncContent();
        }
        return CarouselContent(content: content);
      case TemplateKeys.single_image_template:
        services.tracking.screen.start();
        if (content.categories.any((c) => c.code == AppConstants.masterSync)) {
          return MastersyncContent();
        }
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
