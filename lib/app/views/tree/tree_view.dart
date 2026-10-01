import '/config.dart';

class TreeView extends StatefulWidget {
  const TreeView({super.key});

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  late StreamSubscription<int> currentTreeListener;

  @override
  void initState() {
    services.navigation.initialize();
    currentTreeListener = services.navigation.onTreeIndexChanged.stream.listen((val) {
      if (mounted) {
        setState(() {});
      }
    });
    services.visitedContents = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (services.availableContents.length == 1) {
        Get.back();
        services.navigation.currentContentIndex = 0;
        services.navigation.goContent(context, services.filteredContents[0]);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    currentTreeListener.cancel();
    services.visitedContents = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) {
          return;
        }
        final isFirstRouteInCurrentTab = !await services
            .navigation
            .tabs[services.navigation.currentTreeIndex]
            .currentState!
            .maybePop();
        if (context.mounted && isFirstRouteInCurrentTab) {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFFEDEDED),
        appBar: HeaderWidget(showBackButton: true, title: _setTitle()),
        body: IndexedStack(
          index: services.navigation.currentTreeIndex,
          children: [
            _buildNavigator(TreeViews.list, const AppListView()),
            _buildNavigator(TreeViews.map, const MapView()),
            _buildNavigator(TreeViews.keyboard, const KeyboardView()),
          ],
        ),
        bottomNavigationBar: const TabBarWidget(),
      ),
    );
  }

  Widget _buildNavigator(int index, Widget page) {
    return Navigator(
      key: services.navigation.tabs[index],
      onGenerateRoute: (settings) {
        return GetPageRoute(page: () => page, settings: settings);
      },
    );
  }

  String _setTitle() {
    switch (services.navigation.currentTreeIndex) {
      case TreeViews.keyboard:
        return "i18n.keyboard".tr;
      case TreeViews.map:
        return "i18n.map".tr;
      case TreeViews.list:
        return "i18n.tours".tr;
      default:
        return services.tours.current.title.toUpperCase();
    }
  }
}
