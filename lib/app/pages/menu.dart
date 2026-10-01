import 'package:flutter_html/flutter_html.dart' as html;

import '/config.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  bool showInfo = false;
  bool showLocation = false;
  TemplateInformationScreen? information;
  bool isSurvey = true;

  @override
  void initState() {
    CustomerPlaceContent? content = services.contents.getContentFromAllByTemplate(
      TemplateKeys.information_screen_template,
    );
    if (content != null) {
      information = content.getTemplate<TemplateInformationScreen>();
    }
    CustomerPlaceContent? contentSurvey = services.contents.getContentFromAllByTemplate(TemplateKeys.survey_template);
    isSurvey = contentSurvey != null;
    super.initState();
  }

  void _showLocation() {
    setState(() => showLocation = true);
  }

  void _closeLocation() {
    setState(() => showLocation = false);
  }

  void _showInformation() {
    setState(() => showInfo = true);
  }

  void _closeInformation() {
    setState(() => showInfo = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary700,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsetsGeometry.all(10),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _closeButton(),
                          Stack(
                            children: [
                              if (!(showInfo || showLocation))
                                Column(
                                  children: [
                                    _rowWithIcon(
                                      Icons.translate,
                                      "i18n.menu.language".tr,
                                      () => Get.offAllNamed(AppRoutes.languages),
                                    ),
                                    if (isSurvey) Divider(color: AppTheme.primary100),
                                    if (isSurvey)
                                      _rowWithIcon(
                                        Icons.live_help_outlined,
                                        "i18n.menu.survey".tr,
                                        () => Get.toNamed(AppRoutes.survey),
                                      ),
                                    Divider(color: AppTheme.primary100),
                                    _rowWithIcon(
                                      null,
                                      "i18n.menu.information".tr,
                                      _showInformation,
                                      svg: SvgPicture.asset(
                                        "assets/icons/quick_reference.svg",
                                        colorFilter: const ColorFilter.mode(AppTheme.primary100, BlendMode.srcIn),
                                      ),
                                    ),
                                    Divider(color: AppTheme.primary100),
                                    _rowWithIcon(Icons.location_on_outlined, "i18n.menu.location".tr, _showLocation),
                                    Divider(color: AppTheme.primary100),
                                  ],
                                ),
                              _animatedPage(
                                showInfo,
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _rowWithIcon(
                                      null,
                                      "i18n.menu.information".tr,
                                      _closeInformation,
                                      svg: SvgPicture.asset(
                                        "assets/icons/quick_reference.svg",
                                        colorFilter: const ColorFilter.mode(AppTheme.primary100, BlendMode.srcIn),
                                      ),
                                    ),
                                    Divider(color: AppTheme.primary100),
                                    if (information != null)
                                      if (information!.dropdownList.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 70, top: 16, bottom: 16, right: 24),
                                          child: Html(
                                            data:
                                                '<div style="font-size: 14;font-weight: 300;">${information!.dropdownList.first.content.translateRichText().replaceAll(RegExp(r'<p>\s*<br\s*/?>\s*</p>', caseSensitive: false), '')}</div>',
                                            style: {
                                              "p": html.Style(color: AppTheme.primary100),
                                              "div": html.Style(color: AppTheme.primary100),
                                            },
                                          ),
                                        ),
                                    Divider(color: AppTheme.primary100),
                                  ],
                                ),
                              ),
                              _animatedPage(
                                showLocation,
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _rowWithIcon(Icons.location_on_outlined, "i18n.menu.location".tr, _closeLocation),
                                    Divider(color: AppTheme.primary100),
                                    if (information != null)
                                      if (information!.dropdownList.length > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 70, top: 16, bottom: 16),
                                          child: Html(
                                            data:
                                                '<div style="font-size: 14;font-weight: 300;">${information!.dropdownList[1].content.translateRichText()}</div>',
                                            style: {
                                              "p": html.Style(color: AppTheme.primary100),
                                              "div": html.Style(color: AppTheme.primary100),
                                            },
                                          ),
                                        ),
                                    Divider(color: AppTheme.primary100),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: SvgPicture.asset("assets/svg/logo.svg", width: context.width * 0.2),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                      if (services.ventour.applicationType == ApplicationType.loan)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: SizedBox(
                            child: Text(services.core.app.info.version, style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _animatedPage(bool show, Widget w) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOut,
      height: show ? null : 0,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 600),
        opacity: show ? 1.0 : 0.0,
        child: Container(
          padding: EdgeInsets.only(top: 10),
          decoration: BoxDecoration(),
          child: show ? w : SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _closeButton() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: SafeArea(
            child: IconButton(
              padding: EdgeInsets.only(top: 10),
              onPressed: () {
                if (showInfo || showLocation) {
                  _closeInformation();
                  _closeLocation();
                } else {
                  Get.back();
                }
              },
              icon: Icon(Icons.close, color: AppTheme.primary100, size: 24),
              color: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
          ),
        ),
        SizedBox(height: 10),
        Divider(color: AppTheme.primary100),
      ],
    );
  }

  Widget _rowWithIcon(IconData? icon, String text, Function()? onTap, {Widget? svg}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 26),
            if (icon != null) Icon(icon, color: AppTheme.primary100, size: 24) else svg!,
            SizedBox(width: 20),
            Text(
              text,
              style: TextStyle(
                color: AppTheme.primary100,
                fontSize: 16,
                letterSpacing: -0.01 * 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontSecondary, fontFamilyFallback: AppTheme.fontFallback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
