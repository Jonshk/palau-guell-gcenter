import '/config.dart';

class Toolbar extends StatefulWidget {
  const Toolbar({super.key});

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  double _value = 0;
  late StreamSubscription<int> textSizeListener;

  @override
  void initState() {
    _value = services.textSize.size.toDouble();
    textSizeListener = services.textSize.onTextSizeChange.stream.listen((newSize) {
      setState(() {
        _value = newSize.toDouble();
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    textSizeListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            thumbColor: AppTheme.primary900,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackShape: const RectangularSliderTrackShape(),
            trackHeight: 2,
            inactiveTrackColor: AppTheme.primary800,
            activeTrackColor: AppTheme.primary800,
            overlayShape: SliderComponentShape.noThumb,
          ),
          child: Slider(
            value: _value,
            min: 14,
            max: 26,
            divisions: 3,
            onChanged: (double newValue) {
              setState(() {
                if (newValue > _value) {
                  services.textSize.increase();
                } else {
                  services.textSize.decrease();
                }
                _value = newValue;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 35,
                height: 35,
                child: TextButton(
                  onPressed: () => services.textSize.decrease(),
                  style: ButtonStyle(
                    shape: const WidgetStatePropertyAll<OutlinedBorder?>(CircleBorder()),
                    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(EdgeInsets.all(5)),
                  ),
                  child: Text(
                    "-A",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: services.textSize.checkDisabled()
                          ? AppTheme.primary800.withValues(alpha: 0.5)
                          : AppTheme.primary800,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 35,
                height: 35,
                child: TextButton(
                  onPressed: () => services.textSize.increase(),
                  style: ButtonStyle(
                    shape: const WidgetStatePropertyAll<OutlinedBorder?>(CircleBorder()),
                    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(EdgeInsets.all(5)),
                  ),
                  child: Text(
                    "A+",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: services.textSize.checkDisabled(true)
                          ? AppTheme.primary800.withValues(alpha: 0.5)
                          : AppTheme.primary800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
