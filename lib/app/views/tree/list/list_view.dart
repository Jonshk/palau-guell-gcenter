import '/config.dart';

class AppListView extends StatefulWidget {
  const AppListView({super.key});

  @override
  State<AppListView> createState() => _AppListViewState();
}

class _AppListViewState extends State<AppListView> {
  ScrollController listScrollCtrl = ScrollController();
  late StreamSubscription<int> currentIndexListener;

  @override
  void initState() {
    listScrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToContent();
    });
    super.initState();
  }

  @override
  void dispose() {
    listScrollCtrl.dispose();
    currentIndexListener.cancel();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        spacing: 20,
        children: [
          if (services.ventour.applicationType == ApplicationType.loan) topTour(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(0),
              itemCount: services.ventour.applicationType == ApplicationType.loan
                  ? services.availableContents.length
                  : services.availableContents.length + 1,
              controller: listScrollCtrl,
              itemBuilder: (context, index) {
                if (index == 0 && services.ventour.applicationType != ApplicationType.loan) {
                  return topTour();
                }
                int realIndex = services.ventour.applicationType == ApplicationType.loan ? index : index - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8, top: realIndex == 0 ? 20 : 0),
                  child: ContentCard(
                    content: services.filteredContents[realIndex],
                    onTap: () {
                      services.navigation.currentContentIndex = realIndex;
                      services.navigation.goContent(context, services.filteredContents[realIndex]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget topTour() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.light,
        boxShadow: [
          BoxShadow(color: const Color(0x99000000), offset: const Offset(0, 0), blurRadius: 16, spreadRadius: 0),
        ],
      ),
      child: Stack(
        children: [
          Image(
            image: AppImageProvider(appFile: services.tours.current.tour.card.defaultImage.mediaResource(), tour: true),
            width: context.width,
            height: 151,
            fit: BoxFit.cover,
          ),
          Container(
            width: context.width,
            height: 151,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                stops: [0.0, 0.4882, 1.0],
                colors: [
                  Color.fromRGBO(51, 44, 40, 0.5),
                  Color.fromRGBO(51, 44, 40, 0.6),
                  Color.fromRGBO(51, 44, 40, 0.83),
                ],
              ),
            ),
          ),
          Container(
            width: context.width,
            height: 151,
            alignment: Alignment.center,
            child: Text(
              services.tours.current.title,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.light, fontWeight: FontWeight.w700, fontSize: 28, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToContent() {
    currentIndexListener = services.navigation.onCurrentContentIndexChanged.stream.listen((_) {
      listScrollTo();
      setState(() {});
    });
  }

  Future<void> listScrollTo() async {
    final allContents = services.filteredContents.take(services.navigation.currentContentIndex).toList();
    final int masterSyncCount = allContents
        .where((content) => content.categories.any((c) => c.code == AppConstants.masterSync))
        .length;
    final int nonMasterSyncCount = allContents.length - masterSyncCount;
    double position =
        nonMasterSyncCount * ((context.width - 20) / 2) +
        masterSyncCount * (context.width - 20) +
        (services.ventour.applicationType == ApplicationType.loan ? 151 : 0);
    if (position >= 0) {
      final isFirstRouteInCurrentTab = !services.navigation.tabs[services.navigation.currentTreeIndex].currentState!
          .canPop();
      if (isFirstRouteInCurrentTab) {
        await listScrollCtrl.animateTo(position, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
      }
    }
  }
}
