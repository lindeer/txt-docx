`txt_docx` is a simple tool that could convert plain text files into docx files and vice versa.

## Features

* convert a plain text file into a docx file

* convert a docx file into a plain text

* more smooth api based on stream and transformer

* simply handle large files

* console commands avaiable

* pure Dart without flutter

## Why

There are already many packages could do what `txt_docx` could, but also many shotages.

[docx_to_text](https://pub.dev/packages/docx_to_text) could only convert docx to text, and is not a good choice to handle large files, 'cause it read all file bytes into memories.

[doc_text_extractor](https://pub.dev/packages/doc_text_extractor), [doc_text](https://pub.dev/packages/doc_text), e.g. are available with flutter framework.

## Usage

convert a text file to a docx file:
```dart
  final f = 'your/text/file.txt';
  final docx = '${p.basenameWithoutExtension(f)}.docx';
  final writer = DocxWriter();
  await writer.writeStream(File(f).openRead(), docx);
```

convert a docx file to a text file:
```dart
  final f = File('your/docx/file.docx');
  await f.openRead()
    .transform(DocxDecoder(f.lengthSync()))
    .transform(utf8.encoder)
    .pipe(File('$f.txt').openWrite());
```

## Note

`DocxEncoder` currently is not available, because of [archive](https://pub.dev/packages/archive)'s implementation.
