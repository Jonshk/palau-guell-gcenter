import "/config.dart";

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  StreamSubscription<bool>? _onAppLoaded;
  bool animationEnd = false;

  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    _controller = AnimationController(duration: const Duration(seconds: 3), vsync: this)
      ..forward().then((_) {
        if (services.settings != null) {
          services.navigation.endSplashAnimation = true;
        } else {
          animationEnd = true;
        }
      });
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.ease));
    _onAppLoaded = services.onEndVentourCharge.stream.listen((value) {
      if (animationEnd) {
        services.navigation.endSplashAnimation = animationEnd;
      }
      if (mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _onAppLoaded?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary500,
      body: Stack(
        children: [
          Center(
            child: Container(
              alignment: Alignment.center,
              color: AppTheme.primary500,
              width: context.width * 0.5,
              child: SlideTransition(
                position: _offsetAnimation,
                child: SvgPicture.asset("assets/svg/logo.svg", width: context.width * 0.5),
              ),
            ),
          ),
          if (services.settings != null)
            Align(
              alignment: Alignment.topLeft,
              child: SafeArea(
                child: IconButton(
                  onPressed: () => services.settings!.openSettings(context),
                  icon: const SizedBox(),
                  color: Colors.transparent,
                  highlightColor: Colors.transparent,
                  enableFeedback: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
