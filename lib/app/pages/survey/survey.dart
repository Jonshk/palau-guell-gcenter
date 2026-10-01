import '/config.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  List<int> ratingList = [];
  late final TemplateSurvey survey;

  @override
  void initState() {
    CustomerPlaceContent? content = services.contents.getContentFromAllByTemplate(TemplateKeys.survey_template);
    if (content != null) {
      survey = content.getTemplate<TemplateSurvey>();
      for (var i = 0; i < survey.questions.length; i++) {
        ratingList.add(-1);
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            SizedBox(
              height: 120,
              width: context.width,
              child: SvgPicture.asset(
                "assets/svg/logo.svg",
                colorFilter: const ColorFilter.mode(AppTheme.primary900, BlendMode.srcIn),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (services.alertModal.surveySend)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "i18n.survey.correct".tr,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      Text(
                        survey.basicInformation.title.translateRichText(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          color: AppTheme.primary900,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: context.width - 28 - 28,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    survey.basicInformation.subtitle?.translateRichText() ?? "",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: AppTheme.primary900,
                                      height: 1.35,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32),
                                    child: Column(
                                      children: [
                                        for (var i = 0; i < survey.questions.length; i++)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                survey.questions[i].question.translateRichText(),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primary900,
                                                  height: 1.35,
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              StarsWidget(callbackRating: (rating) => saveRating(rating, i)),
                                              SizedBox(height: 16),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  Divider(color: AppTheme.primary900),
                                  SizedBox(
                                    width: context.width,
                                    height: 62,
                                    child: ElevatedButton(
                                      onPressed: ratingList.any((element) => element == -1)
                                          ? null
                                          : () => sendValoration(),
                                      style: ButtonStyle(
                                        splashFactory: InkRipple.splashFactory,
                                        overlayColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.25)),
                                        minimumSize: WidgetStatePropertyAll(Size(100, 42)),
                                        alignment: Alignment.center,
                                        elevation: const WidgetStatePropertyAll(0),
                                        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                          if (states.contains(WidgetState.disabled)) {
                                            return AppTheme.primary800.withValues(alpha: 0.4);
                                          }
                                          return AppTheme.primary800;
                                        }),
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0))),
                                        ),
                                      ),
                                      child: Text(
                                        'i18n.send'.tr,
                                        style: const TextStyle(
                                          color: AppTheme.light,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void saveRating(int rating, int position) {
    setState(() {
      ratingList[position] = rating;
    });
  }

  void sendValoration() async {
    ToastService.show("i18n.successSend".tr, "i18n.thanks".tr, Colors.green);
    services.alertModal.surveySend = true;
    for (var i = 0; i < survey.questions.length; i++) {
      await Future.delayed(Duration(milliseconds: 10 + i), () {
        services.tracking.creator.survey(
          survey.questions[i].question.translateRichText(),
          ratingList[i],
          survey.questions[i].question.languages[services.languages.main.isoCode]?.uuid ?? "",
        );
      });
    }

    Future.delayed(const Duration(milliseconds: 700), () {
      services.tracking.prepareAndSend();
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
