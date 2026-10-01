import '/config.dart';

class ContentCard extends StatelessWidget {
  final CustomerPlaceContent content;
  final PropertyBasicInformation basicInformation;
  final Function()? onTap;

  ContentCard({super.key, required this.content, this.onTap})
    : basicInformation = content.getTemplate().basicInformation!;

  static Future showModal(BuildContext context, CustomerPlaceContent content, Function() onTap) {
    final mq = MediaQuery.of(context);
    final endTransitionY = (mq.size.height - AppConstants.headerHeight - AppConstants.tabbarHeight - 32 - 153) / mq.size.height;

    return showGeneralDialog(
      context: context,
      transitionDuration: Duration(milliseconds: 400),
      barrierDismissible: true,
      barrierLabel: "",
      barrierColor: Colors.transparent,
      useRootNavigator: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: ContentCard(content: content, onTap: () {
            Navigator.of(context).pop();
            Future.microtask(() => onTap());
          },)
        );
      },
      transitionBuilder:(context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, -1),
            end: Offset(0, endTransitionY - 1 )
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMastersync = content.categories.any((c) => c.code == AppConstants.masterSync);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.light,
        boxShadow: [
          BoxShadow(color: const Color(0x40000000), offset: const Offset(2, 4), blurRadius: 10, spreadRadius: 0),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      width: context.width - 24,
      height: 153,
      child: Stack(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                      image: AppImageProvider(appFile: basicInformation.coverImage.mediaResource()),
                      width: context.width * 0.3,
                      height: 137,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    width: context.width * 0.3,
                    height: 137,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.67, 1.0],
                        colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.6)],
                      ),
                    ),
                  ),
                  if (isMastersync)
                    Center(
                      child: SizedBox(width: context.width * 0.3, child: SvgPicture.asset("assets/svg/mastersync.svg")),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 14,
                    children: [
                      if (content.keyboardCode != '')
                        Row(
                          children: [
                            Icon(Icons.headphones_outlined, size: 20, color: AppTheme.primary900),
                            SizedBox(width: 8),
                            Text(
                              content.keyboardCode.length > 1 ? content.keyboardCode : "0${content.keyboardCode}",
                              style: TextStyle(
                                fontFamily: AppTheme.fontSecondary, fontFamilyFallback: AppTheme.fontFallback,
                                fontSize: 24,
                                letterSpacing: -0.03 * 24,
                                fontWeight: FontWeight.w500,
                                height: 1.08,
                                color: AppTheme.primary900,
                              ),
                            ),
                          ],
                        ),
                      Text(
                        basicInformation.title.translateRichText(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          height: 1.3,
                          color: AppTheme.primary900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}
