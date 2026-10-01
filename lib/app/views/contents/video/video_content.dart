part of '../content.dart';

class VideoContent extends StatelessWidget {
  final CustomerPlaceContent content;
  final TemplateSingleVideo template;
  final GlobalKey<VideoWidgetState> videoKey = GlobalKey<VideoWidgetState>();
  VideoContent({super.key, required this.content}) : template = content.getTemplate();

  @override
  Widget build(BuildContext context) {
    return ListView(
      addAutomaticKeepAlives: true,
      children: [
        if (services.ventour.applicationType != ApplicationType.loan)
          SizedBox(height: kToolbarHeight + 8, child: HeaderWidget()),
        Column(
          children: [
            VideoWidget(
              key: videoKey,
              widgetUuid: template.singleVideo.uuid,
              video: _getMediaResourceVideo(),
              height: context.height * 0.5,
              autoplay: !kIsWeb,
            ),
          ],
        ),
        Padding(padding: EdgeInsetsGeometry.all(16), child: Toolbar()),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
          child: TextWidget(
            title: template.basicInformation.title.translateRichText(),
            uuid: template.basicInformation.uuid,
            text: template.basicInformation.paragraph!.translateRichText(),
          ),
        ),
      ],
    );
  }

  PropertyContent<MediaResourceVideo> _getMediaResourceVideo() {
    if (services.accessibility.config.enableSignLanguage &&
        template.accessibleInformation.signLanguage.getUuid().isEmpty) {
      Logger.warning("NO SIGN LANGUAGE VIDEO FOUND", "VideoContent", "_checkAccessibility");
    }
    if (services.accessibility.config.enableSignLanguage &&
        template.accessibleInformation.signLanguage.getUuid().isNotEmpty) {
      return template.accessibleInformation.signLanguage;
    } else {
      return template.singleVideo.defaultVideo;
    }
  }
}
