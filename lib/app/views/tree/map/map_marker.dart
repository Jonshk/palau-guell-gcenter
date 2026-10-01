part of 'map_view.dart';

class MapViewMarker extends StatelessWidget {
  final Size size;
  final String keyboardCode;
  final String contentUuid;
  final bool isSelected;
  final bool showKeyboardCode;
  final Color backgroundColor;
  final Color colorSelected;
  final Color fontColor;
  final Color fontColorSelected;
  const MapViewMarker({
    super.key,
    required this.size,
    this.keyboardCode = "",
    this.contentUuid = "",
    this.isSelected = false,
    this.showKeyboardCode = false,
    this.backgroundColor = AppTheme.primary700,
    this.colorSelected = AppTheme.primary900,
    this.fontColor = AppTheme.light,
    this.fontColorSelected = AppTheme.light,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.secondary900),
        color: AppTheme.secondary600,
      ),
      child: Text(
        keyboardCode,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontFamily: 'archivo', fontFamilyFallback: AppTheme.fontFallback, color: AppTheme.primary100),
      ),
    );
  }
}
