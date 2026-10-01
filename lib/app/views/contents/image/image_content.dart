part of '../content.dart';

class ImageContent extends StatefulWidget {
  final CustomerPlaceContent content;
  final TemplateSingleImage template;

  ImageContent({super.key, required this.content}) : template = content.getTemplate();

  @override
  State<ImageContent> createState() => _ImageContentState();
}

class _ImageContentState extends State<ImageContent> {
  int audioKey = 0;
  final double playerHeigth = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.content.categories.any((c) => c.code == AppConstants.masterSync)) {
        NavigatorExtension.show(Get.context!, InstructionsModal());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          children: [
            StickyHeader(
              offset: -(context.height * 0.5 + playerHeigth),
              header: Stack(
                children: [
                  Column(
                    children: [
                      if (widget.template.singleImage.defaultImage.mediaResource().url != "")
                        CarouselWidget(
                          widgetUuid: widget.template.singleImage.uuid,
                          images: _getCarouselImages(),
                          trackingCreator: services.tracking.creator,
                          height: MediaQuery.of(context).size.height * 0.5,
                          backgroundColor: Colors.black,
                          paginationPadding: const EdgeInsets.only(bottom: 16),
                          paginationColorSelected: AppTheme.primary500,
                        )
                      else
                        SizedBox(width: context.width, height: 30),
                      SizedBox(height: 30, width: context.width),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    child: AudioPlayerWidget(
                      key: ValueKey('audio_${widget.content.uuid}$audioKey'),
                      autoplay: !kIsWeb,
                      height: playerHeigth,
                      appFile: (services.accessibility.config.enableAudioDescription)
                          ? widget.template.accessibleInformation.audioDescription.mediaResource()
                          : widget.template.accessibleInformation.locution.mediaResource(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      innerPadding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: AppTheme.primary100,
                      iconsColor: AppTheme.primary700,
                      sliderFontColor: AppTheme.primary800,
                      sliderColor: AppTheme.primary700,
                      sliderActiveColor: AppTheme.primary900,
                      sliderInactiveColor: AppTheme.primary700,
                      radius: BorderRadius.all(Radius.circular(24)),
                    ),
                  ),
                ],
              ),
              content: Column(
                children: [
                  Padding(padding: EdgeInsetsGeometry.all(16), child: Toolbar()),
                  Padding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                    child: TextWidget(
                      title: widget.template.basicInformation.title.translateRichText(),
                      subTitle: widget.template.basicInformation.subtitle?.translateRichText(),
                      uuid: widget.template.basicInformation.uuid,
                      text: widget.template.basicInformation.paragraph!.translateRichText(),
                      showMastersync: widget.content.categories.any((c) => c.code == AppConstants.masterSync),
                    ),
                  ),
                  if (services.contents.currentChildren.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: Wrap(
                          children: [
                            FilledButton(
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                minimumSize: WidgetStatePropertyAll(Size.zero),
                                fixedSize: WidgetStatePropertyAll(Size.fromHeight(44)),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                backgroundColor: WidgetStateProperty.resolveWith((states) {
                                  return AppTheme.secondary600;
                                }),
                              ),
                              onPressed: () {
                                services.contents.setCurrent(services.contents.currentChildren.first);
                                services.navigation.addTrackingContentAccess(widget.content.uuid, TrackingMode.tour);
                                Navigator.of(context).pushSlideRight(const ContentChildView()).then((_) {
                                  services.contents.setCurrent(widget.content);
                                  setState(() {
                                    audioKey++;
                                  });
                                });
                              },
                              child: Text(
                                "i18n.child".tr,
                                style: TextStyle(color: AppTheme.light, fontSize: 18, fontWeight: FontWeight.w300),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (services.accessibility.config.enableSignLanguage &&
            widget.template.accessibleInformation.signLanguage.getUuid().isNotEmpty)
          AccessibilityVideoWidget(
            autoplay: !kIsWeb,
            widgetUuid: widget.template.accessibleInformation.uuid,
            video: widget.template.accessibleInformation.signLanguage,
            initialPosition: Offset(
              (context.width - 200) / 2,
              AppConstants.headerHeight + MediaQuery.of(context).padding.top,
            ),
          ),
      ],
    );
  }

  List<AppCarouselWidget> _getCarouselImages() {
    return [AppCarouselWidget(appFile: widget.template.singleImage.defaultImage.mediaResource())];
  }
}
