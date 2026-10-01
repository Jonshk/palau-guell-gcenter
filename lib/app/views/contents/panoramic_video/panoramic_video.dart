part of '../content.dart';

class PanoramicVideo extends StatelessWidget {
  final CustomerPlaceContent content;
  final TemplatePanoramicVideo template;
  final GlobalKey<VrVideoWidgetState> videoKey = GlobalKey<VrVideoWidgetState>();
  PanoramicVideo({super.key, required this.content}) : template = content.getTemplate();

  @override
  Widget build(BuildContext context) {
    return ListView(
      addAutomaticKeepAlives: true,
      children: [
        if (services.ventour.applicationType != ApplicationType.loan)
          SizedBox(height: kToolbarHeight + 8, child: HeaderWidget()),
        Column(
          children: [
            Container(
              color: AppTheme.primary900,
              height: context.height * 0.5,
              child: VrVideoWidget(
                autoplay: !kIsWeb,
                key: videoKey,
                widgetUuid: template.panoramicVideo.uuid,
                video: _getMediaResourceVideo(),
                height: context.height * 0.5,
              ),
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
      Logger.error("NO SIGN LANGUAGE VIDEO FOUND", "VideoContent", "_checkAccessibility");
    }
    if (services.accessibility.config.enableSignLanguage &&
        template.accessibleInformation.signLanguage.getUuid().isNotEmpty) {
      return template.accessibleInformation.signLanguage;
    } else {
      return template.panoramicVideo.video;
    }
  }
}
