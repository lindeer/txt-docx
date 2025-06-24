import 'dart:io';

import 'package:txt_docx/txt_docx.dart';
import 'package:test/test.dart';

const _sample = """
This is the first paragraph of my document.
Here is a second paragraph. It contains some more text.
And finally, a third one. This demonstrates simple text storage.
Special characters like é, à, ç should also work fine.

You can open this .docx file in Microsoft Word or any compatible viewer.
This is paragraph number 0, demonstrating handling of many paragraphs.
""";
void main() {
  test('basic read and write', () async {
    final docx = 'tmp.docx';
    await Stream.value(_sample)
        .transform(DocxEncoder())
        .pipe(File(docx).openWrite());

    final rf = File(docx);
    final text = await DocxDecoder().open(rf.openSync()).join('');
    expect(text, _sample);
    rf.deleteSync();
  });
}
