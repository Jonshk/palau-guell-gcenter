import '/config.dart';

part 'tab_bar_button.dart';

class TabBarWidget extends StatefulWidget {
  const TabBarWidget({super.key});

  @override
  State<TabBarWidget> createState() => _TabBarWidgetState();
}

class _TabBarWidgetState extends State<TabBarWidget> {
  late StreamSubscription<int> currentTreeListener;
  late StreamSubscription<int> currentContentListener;

  @override
  void initState() {
    currentTreeListener = services.navigation.onTreeIndexChanged.stream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
    currentContentListener = services.navigation.onCurrentContentIndexChanged.stream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    currentTreeListener.cancel();
    currentContentListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width - 20,
      height: AppConstants.tabbarHeight + MediaQuery.of(context).padding.bottom,
      padding: kIsWeb ? EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10) : null,
      color: AppTheme.primary100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TabBarButtonWidget(
            label: "i18n.back".tr.toUpperCase(),
            icon: Icon(
              Icons.arrow_back,
              color: services.navigation.hasPrev()
                  ? AppTheme.secondary500
                  : AppTheme.secondary500.withValues(alpha: 0.5),
              size: 28,
            ),
            disable: !services.navigation.hasPrev(),
            onTap: services.navigation.hasPrev() ? services.navigation.prev : null,
          ),
          TabBarButtonWidget(
            label: "i18n.list".tr.toUpperCase(),
            selected: services.navigation.isInTreePage(TreeViews.list),
            icon: Icon(
              Icons.list,
              color: services.navigation.isInTreePage(TreeViews.list) ? AppTheme.primary800 : AppTheme.secondary500,
              size: 28,
            ),
            onTap: () => services.navigation.goTreeNavigation(TreeViews.list),
          ),
          TabBarButtonWidget(
            label: "i18n.map".tr.toUpperCase(),
            selected: services.navigation.isInTreePage(TreeViews.map),
            icon: Icon(
              Icons.location_on_outlined,
              color: services.navigation.isInTreePage(TreeViews.map) ? AppTheme.primary800 : AppTheme.secondary500,
              size: 28,
            ),
            onTap: () => services.navigation.goTreeNavigation(TreeViews.map),
          ),
          TabBarButtonWidget(
            label: "i18n.keyboard".tr.toUpperCase(),
            selected: services.navigation.isInTreePage(TreeViews.keyboard),
            icon: SvgPicture.asset(
              "assets/icons/keyboard.svg",
              colorFilter: ColorFilter.mode(
                services.navigation.isInTreePage(TreeViews.keyboard) ? AppTheme.primary800 : AppTheme.secondary500,
                BlendMode.srcIn,
              ),
              width: 28,
            ),
            onTap: () => services.navigation.goTreeNavigation(TreeViews.keyboard),
          ),
          TabBarButtonWidget(
            label: "i18n.next".tr.toUpperCase(),
            icon: Icon(
              Icons.arrow_forward,
              color: services.navigation.hasNext()
                  ? AppTheme.secondary500
                  : AppTheme.secondary500.withValues(alpha: 0.5),
              size: 28,
            ),
            disable: !services.navigation.hasNext(),
            onTap: services.navigation.hasNext() ? services.navigation.next : null,
          ),
        ],
      ),
    );
  }
}
