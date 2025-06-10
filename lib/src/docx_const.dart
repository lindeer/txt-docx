import 'package:archive/archive.dart'
    show Archive, ArchiveFile, InputFileStream;

extension _ArchiveExt on Archive {
  void addStringFile(String filename, String doc) {
    add(ArchiveFile(
      filename,
      doc.length,
      doc.codeUnits,
    ));
  }
}

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

Archive createDocxArchive(String docFile) {
  final archive = Archive();
  archive.addStringFile('[Content_Types].xml', _contentTypeXml);
  archive.addStringFile('_rels/.rels', _relsXml);
  archive.addStringFile('word/_rels/document.xml.rels', _documentRelsXml);
  archive.addStringFile('word/styles.xml', _stylesXml);
  archive.addStringFile('word/fontTable.xml', _fontTableXml);
  final input = InputFileStream(docFile);
  archive.addFile(ArchiveFile.stream('word/document.xml', input));
  return archive;
}
