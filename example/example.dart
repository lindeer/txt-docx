import 'dart:convert';
import 'dart:io';

import 'package:txt_docx/txt_docx.dart';

void main(List<String> argv) async {
  for (final f in argv) {
    final wf = File(f);
    await wf.openRead()
        .transform(DocxDecoder(wf.lengthSync()))
        .transform(utf8.encoder)
        .pipe(File('$f.txt').openWrite());
  }
}
