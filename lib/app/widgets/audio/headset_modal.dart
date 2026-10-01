import '/config.dart';

class HeadsetModal extends StatefulWidget {
  const HeadsetModal({super.key});

  static Future<T?> show<T>(BuildContext context) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 500),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return const HeadsetModal();
      },
    );
  }

  @override
  State<HeadsetModal> createState() => _HeadsetModalState();
}

class _HeadsetModalState extends State<HeadsetModal> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Center(
        child: IntrinsicHeight(
          child: Container(
            color: AppTheme.light,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 45),
                      Icon(Icons.hearing, size: 64),
                      const SizedBox(height: 30),
                      Text(
                        "i18n.headsetModal.title".tr.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          height: 28 / 20,
                          color: AppTheme.primary900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "i18n.headsetModal.description".tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 18,
                          height: 26 / 18,
                          color: AppTheme.primary900,
                        ),
                      ),
                      SizedBox(height: 14),
                      _checkBox(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: context.width,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: audio.modal.close,
                          style: ButtonStyle(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.25)),
                            minimumSize: WidgetStatePropertyAll(Size(100, 42)),
                            alignment: Alignment.center,
                            elevation: const WidgetStatePropertyAll(0),
                            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                            backgroundColor: const WidgetStatePropertyAll(AppTheme.primary800),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0))),
                            ),
                          ),
                          child: Text(
                            "i18n.accept".tr.toUpperCase(),
                            style: const TextStyle(color: AppTheme.light, fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _closeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkBox() {
    return Stack(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                "i18n.headsetModal.notAgain".tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w300,
                  color: AppTheme.primary900,
                  fontSize: 14,
                  height: 22 / 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(width: 8),
            Transform.translate(
              offset: Offset(-4, 0),
              child: Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  checkColor: AppTheme.primary900,
                  activeColor: Colors.transparent,
                  value: _isChecked,
                  onChanged: _onCheckboxChanged,
                  side: WidgetStateBorderSide.resolveWith((state) => BorderSide(color: AppTheme.primary900, width: 2)),
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                ),
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onTap: () => _onCheckboxChanged(!_isChecked),
            ),
          ),
        ),
      ],
    );
  }

  void _onCheckboxChanged(bool? value) {
    if (value != null) {
      setState(() => _isChecked = value);
      audio.modal.setNotShowAgain(AudioModalType.headset, value);
    }
  }

  Widget _closeButton() {
    return Positioned(
      top: 4,
      right: 4,
      child: IconButton(onPressed: audio.modal.close, icon: const Icon(Icons.close_rounded)),
    );
  }
}
