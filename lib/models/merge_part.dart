// lib/models/merge_part.dart
//
// Response shape for the Worker's POST /parts-merge endpoint (see
// handlePartsMerge in cloudflare-worker/worker.js / PARTS_MERGE_WORKER.js)
// -- the same endpoint cloudflare-site/parts-merger.html uses. The native
// port's scope is deliberately narrower than the website (2026-08-13):
// official LEGO set numbers only (no MOC CSV upload), and only the
// BrickLink Wanted List XML output -- the website's plain PAB/reference
// CSV isn't built here.
//
// The worker always returns its result as CSV text (`Part Number,BrickLink
// Part Number,Color ID,BrickLink Color ID,Color,Quantity,Spare Qty`), not
// JSON rows -- parseMergeCsv re-parses that text, mirroring the shape of
// parts-merger.html's own CSV reader but without its generic header-alias
// matching, since this code only ever sees this one fixed column order
// (no user-uploaded CSV to tolerate here).

class MergedPart {
  final String partNum;
  final String blPartNum; // '' when Rebrickable has no BrickLink mapping
  final String colorId;
  final String blColorId; // '' when unmapped
  final String color;
  final int qty;
  final int spareQty;

  const MergedPart({
    required this.partNum,
    required this.blPartNum,
    required this.colorId,
    required this.blColorId,
    required this.color,
    required this.qty,
    required this.spareQty,
  });

  bool get hasBrickLinkIds => blPartNum.isNotEmpty && blColorId.isNotEmpty;
}

class MergeResult {
  final bool success;
  final List<MergedPart> parts;
  final int setCount;
  final List<String> warnings;
  final String? error; // set only when success is false

  const MergeResult._({
    required this.success,
    required this.parts,
    required this.setCount,
    required this.warnings,
    this.error,
  });

  factory MergeResult.success({
    required List<MergedPart> parts,
    required int setCount,
    required List<String> warnings,
  }) =>
      MergeResult._(
          success: true, parts: parts, setCount: setCount, warnings: warnings);

  factory MergeResult.failure(String error, {List<String> warnings = const []}) =>
      MergeResult._(
          success: false, parts: const [], setCount: 0, warnings: warnings, error: error);
}

List<MergedPart> parseMergeCsv(String text) {
  final rows = _splitCsvRows(text);
  if (rows.length < 2) return [];
  final out = <MergedPart>[];
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    if (r.length < 7) continue;
    final partNum = r[0].trim();
    final qty = int.tryParse(r[5].trim()) ?? 0;
    if (partNum.isEmpty || qty <= 0) continue;
    final color = r[4].trim();
    out.add(MergedPart(
      partNum: partNum,
      blPartNum: r[1].trim(),
      colorId: r[2].trim(),
      blColorId: r[3].trim(),
      color: color.isEmpty ? 'Unknown' : color,
      qty: qty,
      spareQty: int.tryParse(r[6].trim()) ?? 0,
    ));
  }
  return out;
}

// Minimal quoted-aware CSV row splitter -- only the Color column can ever
// contain a comma, but this handles it the same way the worker's own CSV
// writer (and the website's parseCSVText) does rather than assuming it
// never happens.
List<List<String>> _splitCsvRows(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (c == '\n') {
      row.add(field.toString());
      rows.add(row);
      row = [];
      field = StringBuffer();
    } else if (c == '\r') {
      // ignore -- \n (or end of string) closes the row
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows.where((r) => !(r.length == 1 && r[0].trim().isEmpty)).toList();
}

// BrickLink's Wanted List upload format -- same schema as
// parts-merger.html's buildBrickLinkXml (confirmed against BrickLink's own
// docs, help.asp?helpID=2567/207): ITEMTYPE/ITEMID/COLOR/MINQTY, no XML
// declaration (BrickLink's uploader rejects one if present). Rows missing a
// BrickLink part or color id are skipped rather than guessed at -- caller
// surfaces `skipped` so the user knows why the count is lower than the
// merged part count, instead of it just quietly being smaller.
({String xml, int itemCount, int skipped}) buildBrickLinkXml(List<MergedPart> parts) {
  final buf = StringBuffer('<INVENTORY>\n');
  var itemCount = 0, skipped = 0;
  for (final p in parts) {
    if (!p.hasBrickLinkIds) {
      skipped++;
      continue;
    }
    itemCount++;
    buf.write('  <ITEM>\n');
    buf.write('    <ITEMTYPE>P</ITEMTYPE>\n');
    buf.write('    <ITEMID>${_xmlEscape(p.blPartNum)}</ITEMID>\n');
    buf.write('    <COLOR>${_xmlEscape(p.blColorId)}</COLOR>\n');
    buf.write('    <MINQTY>${p.qty}</MINQTY>\n');
    buf.write('    <CONDITION>N</CONDITION>\n');
    buf.write('  </ITEM>\n');
  }
  buf.write('</INVENTORY>');
  return (xml: buf.toString(), itemCount: itemCount, skipped: skipped);
}

String _xmlEscape(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
