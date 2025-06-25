`txt_docx` is a simple tool that could convert plain text files into docx files and vice versa.

## Features

* convert a plain text file into a docx file

* convert a docx file into a plain text

* more smooth api based on stream and transformer

* simply handle large files

* console commands avaiable

* pure Dart without flutter

* async read/write txt and docx files

## Why

There are already many packages could do what `txt_docx` could, but also many shotages.

[docx_to_text](https://pub.dev/packages/docx_to_text) could only convert docx to text, and is not a good choice to handle large files, 'cause it read all file bytes into memories.

[doc_text_extractor](https://pub.dev/packages/doc_text_extractor), [doc_text](https://pub.dev/packages/doc_text), e.g. are available with flutter framework.

Before 2.0.0, `txt_docx` was implemented by `archive`, but it is not stream-friendly, and is [not going to do any refactor to Stream](https://github.com/brendan-duncan/archive/issues/391), another side, `archive`'s implementation is totally sync underlying to read/write files, so I developed a small zip library [zip2](https://pub.dev/packages/zip2), it is async based on stream and stransformer.

## Usage

convert a text file to a docx file:
```dart
final f = 'my.txt';
final docx = 'my.docx';

await File(f)
  .openRead()
  .transform(utf8.decoder)
  .transform(DocxEncoder())
  .pipe(File(docx).openWrite());
```

convert a docx file to a text file:
```dart
final f = 'my.docx';
await DocxDecoder()
  .stream(f)
  .transform(utf8.encoder)
  .pipe(stdout);
```

## Note

`DocxEncoder` is available now, but `DocxDecoder` could not be implemented as `Transformer` because of zip file structure.
