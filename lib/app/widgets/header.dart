import '/config.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const HeaderWidget({super.key, this.showBackButton = false, this.title = ''});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primary500,
      actions: [_menuButton()],
      leading: !showBackButton ? _logo() : _backButton(),
      leadingWidth: !showBackButton ? 114 + 15 : null,
      toolbarHeight: preferredSize.height,
      titleSpacing: 0,
      title: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.fontSecondary, fontFamilyFallback: AppTheme.fontFallback,
          color: AppTheme.primary100,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppConstants.headerHeight);

  Widget _menuButton() {
    return IconButton(
      style: const ButtonStyle(),
      icon: Icon(Symbols.menu, size: 24, color: AppTheme.light),
      onPressed: () {
        Get.toNamed(AppRoutes.menu);
        audio.sensor.enabled = false;
        cancelAudio();
      },
    );
  }

  Widget _logo() {
    return Container(
      width: 114,
      padding: const EdgeInsets.only(left: 15),
      child: SvgPicture.asset("assets/svg/mini-logo.svg", width: 114),
    );
  }

  Widget _backButton() {
    return IconButton(
      onPressed: () async {
        try {
          final navigator = services.navigation.tabs[services.navigation.currentTreeIndex].currentState!;
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            Get.back();
          }
        } catch (e) {
          Get.back();
        }
      },
      constraints: const BoxConstraints(),
      icon: Icon(Symbols.arrow_back_ios, size: 20, color: AppTheme.primary100),
    );
  }
}
