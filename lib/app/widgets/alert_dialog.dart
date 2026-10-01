import '/config.dart';

class AlertModal extends StatelessWidget {
  const AlertModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: IntrinsicHeight(
        child: Container(
          color: AppTheme.light,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 45),
                Icon(Icons.live_help_outlined, color: AppTheme.primary800, size: 100),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(right: 80),
                  child: Text(
                    "i18n.survey.title".tr.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      height: 1.08,
                      letterSpacing: -0.03 * 18,
                      color: AppTheme.primary900,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppTheme.primary800),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "i18n.survey.description".tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.primary900,
                  ),
                ),
                SizedBox(height: 47),
                SizedBox(
                  width: context.width,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Get.toNamed(AppRoutes.survey);
                      cancelAudio();
                    },
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
                SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
