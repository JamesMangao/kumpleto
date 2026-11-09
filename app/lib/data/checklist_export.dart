/// One bundle, written out for somebody else: a plain-text checklist for the
/// share sheet, or a printable PDF.
///
/// Both forms come from the same [_blocks] structure, so what a reader shares on
/// chat and what they print cannot drift apart. The text is whatever the app
/// already shows — the bundle's documents in authored order, their requirements
/// and steps, and the fee/processing/where notes — plus one footer line that
/// says who generated it, when, and that the app is unofficial.
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/app_localizations.dart';
import '../models/localized_text.dart';
import '../models/models.dart';

/// Everything the two renderers need. [languageCode] picks the `en`/`fil` side
/// of every bilingual string, exactly like the screen does.
class ChecklistContent {
  const ChecklistContent({
    required this.l10n,
    required this.languageCode,
    required this.bundle,
    required this.documents,
    required this.agencyOf,
    required this.footer,
  });

  final AppLocalizations l10n;
  final String languageCode;
  final Bundle bundle;
  final List<Document> documents;

  /// Agency display name for a document (falls back to the raw id).
  final String Function(Document) agencyOf;

  /// Last line of the export: generation date plus the unofficial notice.
  final String footer;

  String text(LocalizedText? value) => value?.pick(languageCode) ?? '';

  String name(Document document) => document.name.pick(languageCode);
}

/// The share-sheet form: one `[ ]` line per requirement, numbered steps, and
/// the notes indented under their document.
String checklistText(ChecklistContent content) {
  final out = StringBuffer()
    ..writeln(content.bundle.name.pick(content.languageCode).toUpperCase())
    ..writeln(content.bundle.description.pick(content.languageCode))
    ..writeln();

  for (final block in _blocks(content)) {
    out.writeln(
      '${block.index}. ${block.document.name.pick(content.languageCode)}'
      ' — ${content.agencyOf(block.document)}',
    );
    for (final line in block.requirements) {
      out.writeln('   [ ] $line');
    }
    for (var i = 0; i < block.steps.length; i++) {
      out.writeln('   ${i + 1}) ${block.steps[i]}');
    }
    for (final detail in block.details) {
      out.writeln('   ${detail.label}: ${detail.value}');
    }
    out.writeln();
  }

  out.writeln(content.footer);
  return out.toString().trimRight();
}

/// The printable form: A4, Helvetica, twenty millimetres of margin.
///
/// Only the PDF base-14 font is used (nothing to bundle), which is why the peso
/// sign is written as `PHP` — U+20B1 is outside the font's WinAnsi coverage.
Future<Uint8List> checklistPdf(ChecklistContent content) async {
  final doc = pw.Document(
    title: content.bundle.name.pick(content.languageCode),
  );
  final blocks = _blocks(content);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(20, 20, 20, 20),
      build: (context) => [
        pw.Text(
          content.bundle.name.pick(content.languageCode),
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _pdfSafe(content.bundle.description.pick(content.languageCode)),
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 14),
        for (final block in blocks) ...[
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 6, bottom: 4),
            child: pw.Text(
              '${block.index}. ${_pdfSafe(content.name(block.document))}'
              ' - ${_pdfSafe(content.agencyOf(block.document))}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          for (final line in block.requirements)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
              child: pw.Text(
                '[ ]  ${_pdfSafe(line)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          for (var i = 0; i < block.steps.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
              child: pw.Text(
                '${i + 1}.  ${_pdfSafe(block.steps[i])}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          for (final detail in block.details)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: '${_pdfSafe(detail.label)}: ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.TextSpan(
                      text: _pdfSafe(detail.value),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          pw.SizedBox(height: 8),
        ],
        pw.Divider(),
        pw.Text(
          _pdfSafe(content.footer),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    ),
  );

  return doc.save();
}

/// The outline both renderers share.
List<_Block> _blocks(ChecklistContent content) {
  final l10n = content.l10n;
  final blocks = <_Block>[];
  for (var i = 0; i < content.documents.length; i++) {
    final document = content.documents[i];
    blocks.add(
      _Block(
        index: i + 1,
        document: document,
        requirements: [
          for (final requirement in document.requirements)
            _requirementLine(content, requirement),
        ],
        steps: [for (final step in document.steps) content.text(step)],
        details: [
          if (document.feeNote != null)
            (label: l10n.docFees, value: content.text(document.feeNote)),
          if (document.processingNote != null)
            (
              label: l10n.docProcessing,
              value: content.text(document.processingNote),
            ),
          if (document.whereToApply != null)
            (label: l10n.docWhere, value: content.text(document.whereToApply)),
          if (document.validityMonths != null)
            (
              label: l10n.docValidity,
              value: document.validityMonths == 0
                  ? l10n.docValidForever
                  : l10n.docValidMonths(document.validityMonths!),
            ),
          if (document.sourceUrl != null)
            (label: l10n.docOriginal, value: document.sourceUrl!),
        ],
      ),
    );
  }
  return blocks;
}

/// "Two valid IDs (original, 2 photocopies)" — the same flags the checklist
/// shows as small chips.
String _requirementLine(ChecklistContent content, Requirement requirement) {
  final notes = <String>[
    if (requirement.original) content.l10n.docOriginal.toLowerCase(),
    if (requirement.photocopies > 0)
      content.l10n.docPhotocopies(requirement.photocopies),
    if (requirement.optional) content.l10n.docOptional.toLowerCase(),
  ];
  final text = content.text(requirement.text);
  return notes.isEmpty ? text : '$text (${notes.join(', ')})';
}

/// The base-14 fonts cover Latin-1 only: map the few characters the authored
/// data actually uses outside it, so nothing prints as a missing glyph.
String _pdfSafe(String value) => value
    .replaceAll('₱', 'PHP ')
    .replaceAll('—', '-')
    .replaceAll('–', '-')
    .replaceAll('’', "'")
    .replaceAll('‘', "'")
    .replaceAll('“', '"')
    .replaceAll('”', '"')
    .replaceAll('…', '...');

class _Block {
  const _Block({
    required this.index,
    required this.document,
    required this.requirements,
    required this.steps,
    required this.details,
  });

  final int index;
  final Document document;
  final List<String> requirements;
  final List<String> steps;
  final List<({String label, String value})> details;
}
