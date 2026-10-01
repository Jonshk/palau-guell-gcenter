part of 'keyboard_view.dart';

class KeyboardInput extends StatelessWidget {
  final String value;
  final VoidCallback removeNumber;
  final EdgeInsets padding;
  late final String hintText;
  final double? width;
  KeyboardInput({
    super.key,
    required this.value,
    required this.removeNumber,
    this.padding = const EdgeInsets.fromLTRB(40, 0, 40, 32),
    this.width,
  }) {
    hintText = "i18n.keyboardSearchText".tr;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: padding,
        child: Container(
          width: width,
          height: 30,
          decoration: BoxDecoration(
            color: Color(0xFFEDEDED),
          ),
          child: Center(child: _inputText())));
  }

  Widget _inputText() {
    return Text(value,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppTheme.dark,
        fontSize: 20,
        fontFamily: AppTheme.fontPrimary, fontFamilyFallback: AppTheme.fontFallback,
        fontWeight: FontWeight.w300
      ));
  }
}
