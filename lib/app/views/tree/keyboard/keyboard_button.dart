part of 'keyboard_view.dart';

class KeyboardButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Icon? icon;

  const KeyboardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isNum = label.isNum;

    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 70,
        height: 70,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: isNum ? [BoxShadow(offset: Offset(0, 1), blurRadius: 6, color: AppTheme.dark.withAlpha(64))] : null
        ),
        child:
        SizedBox.expand(
          child: Material(
          color: isNum ? AppTheme.light : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: isNum ?
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: AppTheme.fontPrimary, fontFamilyFallback: AppTheme.fontFallback,
                      color: AppTheme.dark,
                      fontWeight: FontWeight.w300
                    ),
                  )
                  :
                  Stack(
                    children: [
                      Icon(
                        icon!.icon,
                        color: AppTheme.primary500,
                        size: icon!.size,
                      ),
                      icon!,
                    ] 
                  ),
              ) 
            ),
          ),
        )
      ),
    );
  }
}
