import 'dart:convert' show utf8;
import 'dart:io' show stdout;

import 'package:txt_docx/src/docx_decoder.dart';

void main(List<String> argv) async {
  final decoder = DocxDecoder();
  for (final f in argv) {
    await decoder.stream(f).transform(utf8.encoder).pipe(stdout);
  }
}
