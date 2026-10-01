part of 'accesibility.dart';

class AccessibilitySwitch extends StatelessWidget {
  final Widget widget;
  final String label;
  final bool value;
  final bool showButtonBorder;
  final Function(bool) setValue;

  const AccessibilitySwitch({
    super.key,
    required this.widget,
    required this.label,
    required this.value,
    required this.setValue,
    this.showButtonBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 36, height: 36, child: Center(child: widget)),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(fontSize: 16, height: 24 / 16, color: AppTheme.primary900),
          ),
          const Spacer(),
          SizedBox(
            width: 56,
            height: 32,
            child: Switch(
              value: value,
              onChanged: _changeValue,
              inactiveThumbColor: Color(0xFFD3D4D5),
              inactiveTrackColor: Color(0xFFD3D4D5),
              activeTrackColor: Color(0xFFD3D4D5),
              thumbColor: _thumbColor(),
              trackOutlineColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return null;
                }
                return Colors.transparent;
              }),
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                (Set<WidgetState> states) => const Icon(Icons.check_rounded, color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeValue(bool newValue) {
    setValue(newValue);
  }

  WidgetStateProperty<Color?> _thumbColor() {
    return WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.green;
      } else {
        return Colors.red;
      }
    });
  }
}
