part of '../content.dart';

class MastersyncContent extends StatefulWidget {
  const MastersyncContent({super.key});

  @override
  State<MastersyncContent> createState() => _MastersyncContentState();
}

class _MastersyncContentState extends State<MastersyncContent> {
  late final Template template;
  StreamSubscription? _playingStreamSubscription;
  StreamSubscription? _positionStreamSubscription;
  bool _isPlaying = false;
  double _dragDistance = 0.0;
  bool _isDragging = false;

  List<Map<String, dynamic>> subtitles = [];
  String currentSubtitle = "";

  @override
  void initState() {
    super.initState();

    _loadTemplate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIsPlaying();
      services.mastersync.initialize(template.basicInformation?.extras?.mainTranslateRichText() ?? "");
    });
  }

  @override
  void dispose() {
    services.mastersync.dispose();
    _playingStreamSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (_) {
        _isDragging = true;
      },
      onVerticalDragUpdate: (details) {
        if (_isDragging) {
          final newDrag = _dragDistance + details.primaryDelta!;
          if (newDrag >= 0) {
            setState(() {
              _dragDistance = newDrag;
            });
          }
        }
      },
      onVerticalDragEnd: (details) {
        _isDragging = false;
        if (_dragDistance > 100) {
          Navigator.pop(context);
        } else {
          setState(() {
            _dragDistance = 0;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _dragDistance, 0),
        child: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
          child: SizedBox(
            width: context.width,
            height: context.height - 10 - MediaQuery.of(context).padding.top,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          child: Image.asset(
                            "assets/img/mastersync.png",
                            width: context.width,
                            height: context.height - 10 - MediaQuery.of(context).padding.top,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: context.width - 20,
                            height: context.height - 10 - MediaQuery.of(context).padding.top,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                    color: AppTheme.dark.withValues(alpha: 0.5),
                                  ),
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.headphones_outlined, size: 20, color: AppTheme.secondary100),
                                          SizedBox(width: 8),
                                          Text(
                                            services.contents.current.keyboardCode.length > 1
                                                ? services.contents.current.keyboardCode
                                                : "0${services.contents.current.keyboardCode}",
                                            style: TextStyle(
                                              color: AppTheme.secondary100,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w500,
                                              height: 0.83,
                                              letterSpacing: 24 * -0.03,
                                            ),
                                          ),
                                          Spacer(),
                                          IconButton(
                                            onPressed: () => Navigator.pop(context),
                                            icon: Icon(Icons.close, color: AppTheme.light),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Text(
                                          template.basicInformation?.title.translateRichText() ?? "",
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 18,
                                            color: AppTheme.primary100,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Text(
                                          "i18n.instructions.description2".tr,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: 14,
                                            color: AppTheme.light,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Spacer(),
                                if (context.height >= 765)
                                  Align(alignment: Alignment.center, child: SvgPicture.asset("assets/svg/wave.svg")),

                                Container(
                                  width: context.width - 72,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                  child: Text(
                                    (_isPlaying ? "i18n.crv.sincronize" : "i18n.crv.mastersync").tr.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      color: AppTheme.light,
                                      height: 1.08,
                                      letterSpacing: -0.03 * 22,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                                Spacer(),
                                AudioPlayerWidget(
                                  key: services.mastersync.playerKey,
                                  autoplay: false,
                                  height: 60,
                                  appFile: (services.accessibility.config.enableAudioDescription)
                                      ? template.accessibleInformation?.audioDescription.mediaResource() ??
                                            AppFile.empty()
                                      : template.accessibleInformation?.locution.mediaResource() ?? AppFile.empty(),
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  backgroundColor: Colors.transparent,
                                  iconsColor: AppTheme.light,
                                  sliderFontColor: AppTheme.light,
                                  sliderColor: AppTheme.primary600,
                                  sliderActiveColor: AppTheme.primary600,
                                  sliderInactiveColor: AppTheme.light,
                                  onlySlider: true,
                                  disabled: true,
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Stack(
                                    children: [
                                      InkWell(
                                        onTap: services.mastersync.play,
                                        child: _isPlaying
                                            ? SvgPicture.asset("assets/icons/pause.svg")
                                            : SvgPicture.asset("assets/icons/play.svg"),
                                      ),
                                      Obx(() {
                                        return (services.mastersync.isSync.value)
                                            ? SizedBox(
                                                width: 95,
                                                height: 95,
                                                child: CircularProgressIndicator(
                                                  color: AppTheme.primary600,
                                                  strokeWidth: 4,
                                                ),
                                              )
                                            : SizedBox();
                                      }),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _loadTemplate() {
    switch (services.contents.current.templateKey) {
      case TemplateKeys.single_image_template:
        template = services.contents.current.getTemplate<TemplateSingleImage>();
        break;
      case TemplateKeys.carousel_images_template:
        template = services.contents.current.getTemplate<TemplateCarouselImages>();
        break;
      case TemplateKeys.video_template:
        template = services.contents.current.getTemplate<TemplateSingleVideo>();
        break;
      default:
        template = services.contents.current.getTemplate();
        break;
    }
  }

  void _checkIsPlaying() {
    Future.delayed(const Duration(seconds: 1), () {
      _playingStreamSubscription = audio.handler.player.playingStream.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });
    });
  }
}
