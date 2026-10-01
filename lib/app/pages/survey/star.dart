import '/config.dart';

class StarsWidget extends StatefulWidget {
  final Function(int) callbackRating;
  const StarsWidget({super.key, required this.callbackRating});

  @override
  State<StarsWidget> createState() => _StarsWidgetState();
}

class _StarsWidgetState extends State<StarsWidget> {
  int _rating = 0;

  void _updateRating(int rating) {
    setState(() {
      _rating = rating;
    });
    widget.callbackRating(_rating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (int i = 1; i <= 5; i++)
          InkWell(
            onTap: () => _updateRating(i),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.string(_getSvgString(_rating >= i), width: 44, height: 44),
            ),
          ),
      ],
    );
  }

  String _getSvgString(bool isSelected) {
    final fillColor = isSelected ? _colorToHex(AppTheme.terciary400) : _colorToHex(AppTheme.light);

    return '''
    <svg width="17" height="40" viewBox="0 0 17 40" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect x="4.98193" y="24.8608" width="6.12866" height="14.7323" fill="$fillColor"/>
      <path d="M5.45652 30.3109H3.79957L0.899902 26.1557V24.9258H5.45652V30.3109Z" fill="$fillColor" stroke="#4B4C42" stroke-width="1.8"/>
      <path d="M10.7437 30.3109H12.4006L15.3003 26.1557V24.9258H10.7437V30.3109Z" fill="$fillColor" stroke="#4B4C42" stroke-width="1.8"/>
      <path d="M14.6713 24.7498H1.53906L5.56406 0.900024H10.5349L14.6713 24.7498Z" fill="$fillColor"/>
      <path d="M4.75461 30.7252V39.0099H11.4394C11.4394 39.0099 11.4394 33.9606 11.4394 30.7252M1.53906 24.7498H14.6713L10.5349 0.900024H5.56406L1.53906 24.7498Z" stroke="#4B4C42" stroke-width="1.8"/>
      <path d="M4.51172 24.7046L13.0206 14.9841" stroke="#4B4C42" stroke-width="1.8"/>
      <path d="M2.66602 17.4691L11.7793 7.5274" stroke="#4B4C42" stroke-width="1.8"/>
      <path d="M4.09912 9.66007L10.786 2.34894" stroke="#4B4C42" stroke-width="1.8"/>
    </svg>
    ''';
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}
