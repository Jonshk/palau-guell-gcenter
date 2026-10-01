import '/config.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return PopScope(
      canPop: (services.ventour.applicationType != ApplicationType.loan),
      onPopInvokedWithResult: (_, _) async {
        await TerminateRestart.instance.restartApp(options: const TerminateRestartOptions(terminate: true));
      },
      child: Scaffold(
        backgroundColor: AppTheme.light,
        appBar: HeaderWidget(),
        body: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 32,
                children: [
                  ...services.languages.all.map(
                    (CustomerPlaceLanguage language) => Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(46),
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () => select(language),
                        child: Container(
                          height: 46,
                          constraints: BoxConstraints(
                            maxWidth: mq.size.width * (5 / 6),
                            minWidth: mq.size.width * (3 / 4),
                          ),
                          alignment: Alignment.center,
                          decoration: language == services.languages.current
                              ? BoxDecoration(
                                  border: Border.all(color: AppTheme.primary900, width: 1),
                                  borderRadius: BorderRadius.circular(46),
                                )
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 16,
                            children: [
                              Flexible(
                                child: SvgPicture.asset(
                                  "assets/i18n/flags/${language.isoCode}.svg",
                                  width: 28,
                                  height: 28,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "i18n.languages.${language.isoCode}".tr,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontPrimary, fontFamilyFallback: AppTheme.fontFallback,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w300,
                                    color: AppTheme.primary900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> select(CustomerPlaceLanguage language) async {
    services.languages.setCurrent(language);
    services.tracking.creator.languageSelected(language.isoCode);
    services.visitedTours = [];
    Get.updateLocale(Locale(language.isoCode));
    Get.toNamed(AppRoutes.home);
  }
}
