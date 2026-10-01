import '/config.dart';

class ContentOutOfTourView extends StatefulWidget {
  final CustomerPlaceContent content;

  const ContentOutOfTourView({
    super.key,
    required this.content
  });

  @override
  State<ContentOutOfTourView> createState() => _ContentOutOfTourViewState();
}

class _ContentOutOfTourViewState extends State<ContentOutOfTourView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    //services.navigation.tree.index = 2;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderWidget(
        title: widget.content.getTemplate().basicInformation?.title.translateRichText() ?? '',
        showBackButton: true,
      ),
      backgroundColor: AppTheme.primary100,
      body: navigateToContent(widget.content),
      //bottomNavigationBar: const SizedBox(),
    );
  }

  Widget navigateToContent(CustomerPlaceContent content) {
    switch (content.templateKey) {
      case TemplateKeys.carousel_images_template:
        return CarouselContent(content: content);
      case TemplateKeys.single_image_template:
        return ImageContent(content: content);
      default:
        //services.headerTitle.title = "i18n.contentNotAvailable".tr;
        return Center(
            child: Text("i18n.contentNotAvailable".tr,
                style: const TextStyle(fontSize: 20, fontFamily: AppTheme.fontPrimary, fontFamilyFallback: AppTheme.fontFallback, color: Color(0xFF8E2F2F),)));
    }
  }
}