import '/config.dart';

part 'accessibility_switch.dart';

class AccesibilityModal extends StatefulWidget {
  final Function()? onTap;
  const AccesibilityModal({super.key, this.onTap});

  @override
  State<AccesibilityModal> createState() => _AccesibilityModalState();
}

class _AccesibilityModalState extends State<AccesibilityModal> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: IntrinsicHeight(
        child: ColoredBox(
          color: AppTheme.light,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Text(
                        "i18n.accessibility.title".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          height: 28 / 20,
                          color: AppTheme.primary900,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "i18n.accessibility.description".tr,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppTheme.primary900,
                        fontWeight: FontWeight.w300,
                        height: 26 / 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (services.tours.getAccessibility(services.tours.current.tour).enableAudioDescription)
                      AccessibilitySwitch(
                        widget: const Icon(
                          Symbols.audio_description,
                          size: 24,
                          color: AppTheme.primary800,
                          weight: 400,
                        ),
                        label: "i18n.accessibility.enableAudioDescription".tr,
                        value: services.accessibility.config.enableAudioDescription,
                        setValue: _enableAudioDescription,
                      ),
                    Divider(color: Color(0xFFD3D4D5), thickness: 0.32),
                    if (services.tours.getAccessibility(services.tours.current.tour).enableSignLanguage)
                      AccessibilitySwitch(
                        widget: SvgPicture.asset("assets/icons/sign.svg"),
                        label: "i18n.accessibility.enableSignLanguage".tr,
                        value: services.accessibility.config.enableSignLanguage,
                        setValue: _enableSignLanguage,
                      ),
                    if (services.tours.getAccessibility(services.tours.current.tour).enableSubtitles)
                      AccessibilitySwitch(
                        widget: const Icon(Symbols.sign_language, size: 24, color: AppTheme.primary800, weight: 400),
                        label: "i18n.accessibility.enableSubtitles".tr,
                        value: services.accessibility.config.enableSubtitles,
                        setValue: _enableSubtitles,
                      ),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: context.width,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: widget.onTap,
                          style: ButtonStyle(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.25)),
                            minimumSize: WidgetStatePropertyAll(Size(100, 42)),
                            alignment: Alignment.center,
                            elevation: const WidgetStatePropertyAll(0),
                            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                            backgroundColor: const WidgetStatePropertyAll(AppTheme.primary800),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0))),
                            ),
                          ),
                          child: Text(
                            "i18n.accept".tr.toUpperCase(),
                            style: const TextStyle(color: AppTheme.light, fontSize: 20, fontWeight: FontWeight.w500),
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
      ),
    );
  }

  void _enableSignLanguage(bool value) {
    services.accessibility.config.enableSignLanguage = value;
    if (services.accessibility.config.enableSignLanguage && services.accessibility.config.enableAudioDescription) {
      services.accessibility.config.enableAudioDescription = false;
    }
    setState(() {});
  }

  void _enableAudioDescription(bool value) {
    services.accessibility.config.enableAudioDescription = value;
    if (services.accessibility.config.enableSignLanguage && services.accessibility.config.enableAudioDescription) {
      services.accessibility.config.enableSignLanguage = false;
    }
    setState(() {});
  }

  void _enableSubtitles(bool value) {
    services.accessibility.config.enableSubtitles = value;
    services.accessibility.config.enableSubtitles = false;
    setState(() {});
  }
}
