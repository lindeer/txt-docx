import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:txt_docx/txt_docx.dart';

void main(List<String> argv) async {
  for (final f in argv) {
    final docx = '${p.basenameWithoutExtension(f)}.docx';

    final file = File(f);
    final writer = DocxWriter();
    await writer.writeStream(file.openRead(), docx);

    final wf = File(docx);
    await wf
        .openRead()
        .transform(DocxDecoder(wf.lengthSync()))
        .transform(utf8.encoder)
        .pipe(File('$docx.txt').openWrite());
  }
}
