import 'package:flutter/widgets.dart';
import '../services/locale_service.dart';

class LocalizedText extends StatelessWidget {
  final String keyName;
  final Map<String, String>? params;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LocalizedText(
    this.keyName, {
    super.key,
    this.params,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.instance.languageCode,
      builder: (context, _, __) {
        final txt = LocaleService.instance.t(keyName, params);
        return Text(
          txt,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}
