import '/config.dart';

part 'keyboard_button.dart';
part 'keyboard_input.dart';

class KeyboardView extends StatefulWidget {
  const KeyboardView({super.key});

  @override
  State<KeyboardView> createState() => _KeyboardViewState();
}

class _KeyboardViewState extends State<KeyboardView> with AutomaticKeepAliveClientMixin {
  List<CustomerPlaceContent> foundContent = [];
  String currentNumber = "";
  bool nothingFoundInTour = false;
  bool outOfTour = false;

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  bool get wantKeepAlive => false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (nothingFoundInTour) _contentNotFound(),
        if (outOfTour && !nothingFoundInTour) _outOfTour(),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: KeyboardInput(width: context.width, value: currentNumber, removeNumber: _removeNumber),
              ),
              _createKeyboard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createKeyboard() {
    return GridView.count(
      crossAxisCount: 3,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      mainAxisSpacing: 6,
      crossAxisSpacing: 18,
      padding: const EdgeInsets.fromLTRB(49, 0, 49, 34),
      children: [
        KeyboardButton(label: "1", onPressed: () => _addNumber("1")),
        KeyboardButton(label: "2", onPressed: () => _addNumber("2")),
        KeyboardButton(label: "3", onPressed: () => _addNumber("3")),
        KeyboardButton(label: "4", onPressed: () => _addNumber("4")),
        KeyboardButton(label: "5", onPressed: () => _addNumber("5")),
        KeyboardButton(label: "6", onPressed: () => _addNumber("6")),
        KeyboardButton(label: "7", onPressed: () => _addNumber("7")),
        KeyboardButton(label: "8", onPressed: () => _addNumber("8")),
        KeyboardButton(label: "9", onPressed: () => _addNumber("9")),
        const SizedBox(),
        KeyboardButton(label: "0", onPressed: () => _addNumber("0")),
        KeyboardButton(
          label: "",
          onPressed: currentNumber.isNotEmpty ? () => _removeNumber() : null,
          icon: const Icon(Symbols.backspace, fill: 1, size: 28),
        ),
      ],
    );
  }

  Widget _outOfTour() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        //color: AppTheme.light,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          Text(
            "i18n.keyboards.contentOutOfTour".tr,
            style: const TextStyle(fontSize: 18, color: Color(0xFF8F5C14), fontWeight: FontWeight.w500),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppTheme.primary800),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(4))),
              fixedSize: WidgetStatePropertyAll(Size.fromHeight(56)),
            ),
            onPressed: () => ContentCard.showModal(
              context,
              foundContent[0],
              () => services.navigation.openContentOutOfTour(context, foundContent[0]),
            ),
            child: Text(
              "i18n.ok".tr,
              style: const TextStyle(fontSize: 20, color: AppTheme.light, fontWeight: FontWeight.w500),
            ),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.transparent),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(4))),
            ),
            onPressed: () {
              currentNumber = '';
              _search();
            },
            child: Text(
              "i18n.cancel".tr,
              style: const TextStyle(fontSize: 20, color: AppTheme.dark, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentNotFound() {
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: Colors.transparent,
      child: Column(
        children: [
          Icon(Symbols.report, size: 48, color: Color(0xFF8E2F2F)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Text(
              "i18n.keyboards.contentNotFoundInAnyTour".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8E2F2F),
                fontFamily: AppTheme.fontPrimary,
                fontFamilyFallback: AppTheme.fontFallback,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addNumber(String number) {
    if (currentNumber.length < 4) {
      setState(() {
        currentNumber += number;
      });
      _search();
      if (currentNumber == AppConstants.loanKeyboardCode) {
        services.sendTrackingByKeyboard();
      }
    }
  }

  void _removeNumber() {
    setState(() {
      if (currentNumber.isNotEmpty) {
        currentNumber = currentNumber.substring(0, currentNumber.length - 1);
      }
    });
    _search();
  }

  void _search() {
    setState(() {
      foundContent = [];
      outOfTour = false;
      if (currentNumber.isEmpty) {
        return;
      }
      String cleanNumber = currentNumber.isEmpty ? "" : int.tryParse(currentNumber)?.toString() ?? currentNumber;
      if (cleanNumber == "0") cleanNumber = "1";

      var foundByKeyboard = services.contents.getContentByKeyboard(cleanNumber);
      var content = (foundByKeyboard != null && services.isContentHidden(foundByKeyboard)) ? null : foundByKeyboard;
      if (content != null) {
        foundContent.add(content);
        ContentCard.showModal(
          context,
          content,
          () => services.navigation.goContent(context, content, TrackingMode.keyboard),
        );
        services.tracking.creator.keyboardSearch(currentNumber, true);
      } else {
        foundContent = services.contents
            .findAllByKeyboard(currentNumber)
            .where((found) => !services.isContentHidden(found))
            .toList();
        if (foundContent.isNotEmpty) {}
        outOfTour = true;
      }
      _removeContentList();
      nothingFoundInTour = (foundContent.isEmpty && currentNumber.isNotEmpty);
    });
  }

  void _removeContentList() {
    foundContent.removeWhere((content) => content.templateKey == TemplateKeys.content_list_template);
  }
}
