part of 'tab_bar.dart';

class TabBarButtonWidget extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool selected;
  final bool disable;
  final void Function()? onTap;

  const TabBarButtonWidget({
    super.key,
    this.label = "",
    required this.icon,
    this.selected = false,
    this.disable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.width / 5,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: const LinearBorder(side: BorderSide(color: Colors.transparent)),
          elevation: 0,
          padding: const EdgeInsets.all(0),
          disabledBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (label != "") SizedBox(height: 4),
            SizedBox(width: 35, height: 35, child: icon),
            if (label != "")
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontSecondary, fontFamilyFallback: AppTheme.fontFallback,
                    color: selected
                        ? AppTheme.primary800
                        : disable
                        ? AppTheme.secondary500.withValues(alpha: 0.5)
                        : AppTheme.secondary500,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.03 * 10,
                    height: 1.08,
                  ),
                ),
              ),
            if (label != "") SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
