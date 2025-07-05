import 'dart:convert' show utf8;

import 'package:zip2/zip2.dart' show ZipArchive, ZipFileEntry;

const _contentTypeXml = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/fontTable.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml"/>
</Types>
""";

const _relsXml = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
""";

const _documentRelsXml = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable" Target="fontTable.xml"/>
</Relationships>
""";

const _stylesXml = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
        <w:sz w:val="22"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault/>
  </w:docDefaults>
</w:styles>
""";

const _fontTableXml = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:fonts xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:font w:name="Calibri">
    <w:family w:val="swiss"/>
    <w:charset w:val="0"/>
    <w:pitch w:val="variable"/>
    <w:sig post="0" usb0="16777216" usb1="268435456" usb2="0" usb3="0"/>
  </w:font>
</w:fonts>
""";

/// A utility function that bind the document xml stream to a [ZipArchive], a
/// docx file is just a zip file.
ZipArchive createDocxArchive(Stream<List<int>> xml) {
  return ZipArchive([
    _makeEntry('[Content_Types].xml', _contentTypeXml),
    _makeEntry('_rels/.rels', _relsXml),
    _makeEntry('word/_rels/document.xml.rels', _documentRelsXml),
    _makeEntry('word/styles.xml', _stylesXml),
    _makeEntry('word/fontTable.xml', _fontTableXml),
    ZipFileEntry(name: 'word/document.xml', data: xml),
  ]);
}

ZipFileEntry _makeEntry(String name, String content) {
  return ZipFileEntry(name: name, data: Stream.value(utf8.encode(content)));
}

/// A utility extension that get document entry directly from a `ZipArchive`.
/// It would be invalid docx file if its entries do not contain
/// `word/document.xml`.
extension ZipArchiveExt on ZipArchive {
  ZipFileEntry get doc => this['word/document.xml']!;
}
