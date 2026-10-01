import 'package:flutter_html/flutter_html.dart' as html;

import '/config.dart';

class TextWidget extends StatefulWidget {
  final String? uuid;
  final String? text;

  final String? title;
  final String? subTitle;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final bool showMastersync;
  const TextWidget({
    super.key,
    this.uuid,
    this.text,
    this.backgroundColor,
    this.padding,
    this.title,
    this.subTitle,
    this.showMastersync = false,
  });

  @override
  State<TextWidget> createState() => _TextWidgetState();
}

class _TextWidgetState extends State<TextWidget> {
  late StreamSubscription<int> textSizeListener;
  int _size = 0;

  @override
  void initState() {
    if (widget.uuid != null) {
      services.textSize.uuid = widget.uuid!;
      _size = services.textSize.size;
      textSizeListener = services.textSize.onTextSizeChange.stream.listen((newSize) {
        setState(() {
          _size = newSize;
        });
      });
    } else {
      services.textSize.uuid = "";
    }
    super.initState();
  }

  @override
  void dispose() {
    textSizeListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      color: widget.backgroundColor,
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null && widget.title!.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      widget.title!.toUpperCase(),
                      style: TextStyle(
                        fontSize: _size.toDouble() + 6,
                        fontWeight: FontWeight.w600,
                        height: 1.08,
                        letterSpacing: -0.03 * (_size.toDouble() + 6),
                        color: AppTheme.primary900,
                      ),
                    ),
                  ),
                ),
                if (widget.showMastersync)
                  FilledButton(
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                      minimumSize: WidgetStatePropertyAll(Size.zero),
                      fixedSize: WidgetStatePropertyAll(Size.fromHeight(44)),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        return AppTheme.secondary800;
                      }),
                    ),
                    onPressed: () {
                      cancelAudio();
                      NavigatorExtension.show(context, MastersyncContent(), barrierDismissible: false).then((_) {
                        cancelAudio();
                      });
                    },
                    child: Text(
                      "i18n.instructions.button".tr,
                      style: TextStyle(color: AppTheme.light, fontSize: 18, fontWeight: FontWeight.w300),
                    ),
                  ),
              ],
            ),
          SizedBox(height: 16),
          if (widget.subTitle != null && widget.subTitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                widget.subTitle!,
                style: TextStyle(
                  fontSize: _size.toDouble() + 3,
                  fontWeight: FontWeight.w500,
                  height: 1.08,
                  letterSpacing: -0.03 * (_size.toDouble() + 3),
                  color: AppTheme.primary900,
                ),
              ),
            ),
          if (widget.subTitle != null && widget.subTitle!.isNotEmpty) SizedBox(height: 16),
          if (widget.text != null && widget.text!.isNotEmpty)
            Html(
              data: '<div style="font-size: $_size;font-weight: 300;">${removeTags(widget.text ?? "")}</div>',
              style: {
                "p": html.Style(color: AppTheme.primary900),
                "div": html.Style(color: AppTheme.primary900),
              },
            ),
        ],
      ),
    );
  }
}

String removeTags(String htmlString) {
  String noTags = htmlString.replaceAll(RegExp(r'<font[^>]*>'), '');
  noTags = noTags.replaceAll('</font>', '');

  noTags = noTags.replaceAll(RegExp(r'style="[^"]*"', caseSensitive: false), '');

  noTags = noTags.replaceAll(RegExp(r'<table[^>]*>'), '');
  noTags = noTags.replaceAll('</table>', '');

  noTags = noTags.replaceAll(RegExp(r'<tbody[^>]*>'), '');
  noTags = noTags.replaceAll('</tbody>', '');

  noTags = noTags.replaceAll(RegExp(r'<tr[^>]*>'), '');
  noTags = noTags.replaceAll('</tr>', '');

  noTags = noTags.replaceAll(RegExp(r'<td[^>]*>'), '');
  noTags = noTags.replaceAll('</td>', '');
  final divRegex = RegExp(r'<div[^>]*>', caseSensitive: false);
  final match = divRegex.firstMatch(noTags);

  if (match != null && match.start > 0) {
    final start = match.start;
    final beforeDiv = noTags.substring(0, start).trim();
    final afterDiv = noTags.substring(start);
    if (beforeDiv.isNotEmpty) {
      noTags = '<div>$beforeDiv</div> $afterDiv';
    }
  } else if (match == null && noTags.trim().isNotEmpty) {
    noTags = '<div>${noTags.trim()}</div>';
  }
  return noTags;
}
