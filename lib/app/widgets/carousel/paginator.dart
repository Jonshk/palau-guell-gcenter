part of 'carousel_image.dart';

class PageIndicatorWidget extends StatelessWidget {
  final int currentPageIndex;
  final TabController tabController;
  final void Function(int) onUpdateCurrentPageIndex;
  final EdgeInsets? padding;
  final Color? color;
  final Color? colorSelected;

  const PageIndicatorWidget(
      {super.key,
      required this.tabController,
      required this.currentPageIndex,
      required this.onUpdateCurrentPageIndex,
      this.padding,
      this.color = Colors.white,
      this.colorSelected = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(tabController.length, (index) {
          return GestureDetector(
            onTap: () => onUpdateCurrentPageIndex(index),
            child: Container(
              width: index == currentPageIndex ? 20.0 : 10.0,
              height: 10.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: index == currentPageIndex ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: index == currentPageIndex ? BorderRadius.circular(24.0) : null,
                color: index == currentPageIndex ? colorSelected : color,
              ),
            ),
          );
        }),
      ),
    );
  }
}

