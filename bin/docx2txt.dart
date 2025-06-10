import 'dart:convert' show utf8;
import 'dart:io' show File, stdout;

import 'package:txt_docx/txt_docx.dart' show DocxDecoder;

void main(List<String> argv) async {
  for (final f in argv) {
    final file = File(f);
    await file
        .openRead()
        .transform(DocxDecoder(file.lengthSync()))
        .transform(utf8.encoder)
        .pipe(stdout);
  }
}
