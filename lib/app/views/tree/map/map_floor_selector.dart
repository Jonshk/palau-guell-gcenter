part of 'map_view.dart';

class MapFloorSelector extends StatefulWidget {
  final Function(int) onFloordChanged;
  final bool showFloorsTitle;
  final bool showFloorsLabel;
  final String floorButtonLabel;
  const MapFloorSelector({
    super.key,
    required this.onFloordChanged,
    this.showFloorsTitle = false,
    this.showFloorsLabel = false,
    this.floorButtonLabel = "i18n.floor",
  });

  @override
  State<MapFloorSelector> createState() => _MapFloorSelectorState();
}

class _MapFloorSelectorState extends State<MapFloorSelector> {
  bool isMenuOpen = false;
  int? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = services.maps.tourMaps.first.floor;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: services.maps.tourMaps.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12,),
      itemBuilder: (context, index) => index == 0 ? Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _floorButton(services.maps.tourMaps[index]),
      ) : _floorButton(services.maps.tourMaps[index]),
    );
  }

  Widget _floorButton(CustomerPlaceMap map) {
    return FilledButton(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(4))),
        fixedSize: WidgetStatePropertyAll(Size.fromHeight(44)),
        /* fixedSize: WidgetStatePropertyAll(Size.fromHeight(44)),
        minimumSize: WidgetStatePropertyAll(Size.fromHeight(44)),
        maximumSize: WidgetStatePropertyAll(Size.fromHeight(44)), */
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) || map.floor == services.maps.currentFloor) {
            return AppTheme.secondary700;
          } else {
            return AppTheme.secondary600;
          }
        })
      ),
      onPressed: () => widget.onFloordChanged(map.floor),
      child: Text(
        "i18n.maps.${map.floor}".tr,
        style: TextStyle(
          color: AppTheme.light,
          fontSize: 18,
          fontWeight: FontWeight.w300
        ),
      ),
    );
  }
}
