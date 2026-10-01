import '/config.dart';

class InstructionsModal extends StatelessWidget {
  const InstructionsModal({super.key});

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
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.dark),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      SvgPicture.asset(
                        "assets/svg/tv.svg",
                        width: 100,
                        colorFilter: const ColorFilter.mode(AppTheme.primary800, BlendMode.srcIn),
                      ),
                      Text(
                        "i18n.instructions.title".tr.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          height: 28 / 20,
                          color: AppTheme.primary900,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: _buildDescriptionSpans("i18n.instructions.description".tr),
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 18,
                          height: 26 / 18,
                          color: AppTheme.primary900,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: context.width,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildDescriptionSpans(String text) {
    final regex = RegExp(r'\*\*(.+?)\*\*');
    final spans = <InlineSpan>[];
    int start = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1)!.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Velino Sans', fontFamilyFallback: AppTheme.fontFallback,
            fontWeight: FontWeight.w500,
            fontSize: 18,
            height: 26 / 18,
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
}
