import 'dart:async' show StreamController, StreamSink, StreamTransformerBase;
import 'dart:convert' show LineSplitter, utf8;
import 'dart:typed_data' show Uint8List;

import 'package:async/async.dart' show ChunkedStreamReader;
import 'package:archive/archive.dart';

extension _ArchiveExt on Archive {

  void addStringFile(String filename, String doc) => add(ArchiveFile(
    filename,
    doc.length,
    doc.codeUnits,
  ));
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

final class DocxEncoder extends StreamTransformerBase<String, List<int>> {
  final int _length;

  const DocxEncoder(this._length);

  @override
  Stream<List<int>> bind(Stream<String> stream) {
    final archive = Archive();
    archive.addStringFile('[Content_Types].xml', _contentTypeXml);
    archive.addStringFile('_rels/.rels', _relsXml);
    archive.addStringFile('word/_rels/document.xml.rels', _documentRelsXml);
    archive.addStringFile('word/styles.xml', _stylesXml);
    archive.addStringFile('word/fontTable.xml', _fontTableXml);

    final lines = stream.transform(LineSplitter());
    final xml = _docStream(lines);
    final reader = _BytesReader(xml.transform(utf8.encoder), _length);
    final input = InputFileStream.withFileHandle(reader);
    archive.addFile(ArchiveFile.stream('word/document.xml', input));
    final ctrl = StreamController<List<int>>();
    final encoder = ZipEncoder();
    final writer = _BytesWriter(ctrl.sink, -1);
    final output = OutputFileStream.withFileHandle(writer);
    encoder.encodeStream(archive, output);
    return ctrl.stream;
  }

  Stream<String> _docStream(Stream<String> lines) async* {
    yield '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>';
    await for (final line in lines) {
      yield '<w:p><w:r><w:t>';
      yield line.replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');
      yield '</w:t></w:r></w:p>';
    }
    yield '</w:body></w:document>';
  }
}

class _BytesReader implements AbstractFileHandle {
  final ChunkedStreamReader<int> _reader;
  final int _length;
  int _pos;

  _BytesReader(Stream<List<int>> stream, this._length)
      : _reader = ChunkedStreamReader<int>(stream)
      , _pos = 0;


  @override
  int get position => _pos;

  @override
  set position(int p) => _pos = p;

  @override
  int get length => _length;

  @override
  Future<void> close() {
    return _reader.cancel();
  }

  @override
  void closeSync() {
  }

  @override
  bool get isOpen => throw UnimplementedError();

  @override
  bool open({FileAccess mode = FileAccess.read}) {
    throw UnimplementedError();
  }

  @override
  int readInto(Uint8List buffer, [int? length]) {
    final len = length ?? buffer.length;
    /*
    final data = await _reader.readChunk(len);
    buffer.setRange(0, len, data);
    */
    return len;
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    throw UnimplementedError();
  }
}

class _BytesWriter implements AbstractFileHandle {
  final StreamSink<List<int>> sink;
  final int _length;
  int _pos = 0;

  _BytesWriter(this.sink, this._length);

  @override
  int get position => _pos;

  @override
  set position(int p) => _pos = p;

  @override
  int get length => _length;

  @override
  Future<void> close() => sink.close();

  @override
  void closeSync() => throw UnimplementedError();

  @override
  bool get isOpen => throw UnimplementedError();

  @override
  bool open({FileAccess mode = FileAccess.read}) {
    throw UnimplementedError();
  }

  @override
  int readInto(Uint8List buffer, [int? length]) {
    throw UnimplementedError();
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    sink.add(buffer.sublist(start, end));
  }
}
