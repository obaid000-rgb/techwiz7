import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';

const String kStoreName = 'Fandom Verse';
const String kStoreTagline = 'Official Merchandise Store - Pocket Edition';

/// Builds printable PDF invoices for (simulated) orders. The PDF uses only
/// the built-in Helvetica font, so text is kept to plain ASCII.
class InvoiceService {
  static final InvoiceService instance = InvoiceService._();
  InvoiceService._();

  static String money(double v) => '\$${v.toStringAsFixed(2)}';

  static String date(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<Uint8List> buildPdf(
    OrderModel order, {
    required String customerName,
    required String customerEmail,
  }) async {
    const purple = PdfColor.fromInt(0xFF8B5CF6);
    const cyan = PdfColor.fromInt(0xFF06B6D4);
    const ink = PdfColor.fromInt(0xFF111827);
    const muted = PdfColor.fromInt(0xFF6B7280);
    const line = PdfColor.fromInt(0xFFE5E7EB);

    final doc = pw.Document(title: 'Invoice ${order.invoiceNumber}', author: kStoreName);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header band
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(colors: [purple, cyan]),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(kStoreName.toUpperCase(),
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                        pw.SizedBox(height: 2),
                        pw.Text(kStoreTagline, style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text(order.invoiceNumber, style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),
            // Meta + billed to
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _label('BILLED TO', muted),
                      pw.SizedBox(height: 4),
                      pw.Text(customerName.isEmpty ? 'Customer' : customerName,
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ink)),
                      if (customerEmail.isNotEmpty)
                        pw.Text(customerEmail, style: const pw.TextStyle(fontSize: 10, color: muted)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _meta('Invoice no.', order.invoiceNumber, ink, muted),
                    _meta('Order', order.displayNumber, ink, muted),
                    _meta('Issued', date(order.createdAt), ink, muted),
                    _meta('Status', order.status, ink, muted),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 22),
            // Items table
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: line, width: 0.6),
                bottom: pw.BorderSide(color: line, width: 0.6),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(5),
                1: pw.FlexColumnWidth(1.2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F0FF)),
                  children: [
                    _cell('ITEM', bold: true, color: muted),
                    _cell('QTY', bold: true, color: muted, right: true),
                    _cell('UNIT PRICE', bold: true, color: muted, right: true),
                    _cell('AMOUNT', bold: true, color: muted, right: true),
                  ],
                ),
                for (final item in order.items)
                  pw.TableRow(children: [
                    _cell(item.name, color: ink),
                    _cell('${item.quantity}', color: ink, right: true),
                    _cell(money(item.price), color: ink, right: true),
                    _cell(money(item.lineTotal), color: ink, right: true),
                  ]),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Transform.rotate(
                    angle: 0.12,
                    child: pw.Container(
                      width: 150,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.green700, width: 2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(children: [
                        pw.Text('PAID', style: pw.TextStyle(color: PdfColors.green700, fontSize: 20, fontWeight: pw.FontWeight.bold, letterSpacing: 3)),
                        pw.Text('SIMULATED', style: const pw.TextStyle(color: PdfColors.green700, fontSize: 8)),
                      ]),
                    ),
                  ),
                  ),
                ),
                pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _total('Subtotal', money(order.subtotal), ink, muted),
                      pw.Divider(color: line),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: ink)),
                          pw.Text(money(order.total),
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: purple)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Divider(color: line),
            pw.Text('Thank you for shopping at $kStoreName!',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: ink)),
            pw.SizedBox(height: 2),
            pw.Text(
              'This invoice was generated automatically for a simulated purchase. '
              'No payment was taken and no items will be shipped.',
              style: const pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// Opens the platform share/save sheet (downloads the file on web).
  Future<void> share(OrderModel order, {required String customerName, required String customerEmail}) async {
    final bytes = await buildPdf(order, customerName: customerName, customerEmail: customerEmail);
    await Printing.sharePdf(bytes: bytes, filename: '${order.invoiceNumber}.pdf');
  }

  /// Opens the system print dialog / preview.
  Future<void> printInvoice(OrderModel order,
      {required String customerName, required String customerEmail}) async {
    await Printing.layoutPdf(
      name: order.invoiceNumber,
      onLayout: (_) => buildPdf(order, customerName: customerName, customerEmail: customerEmail),
    );
  }

  static pw.Widget _label(String text, PdfColor color) => pw.Text(text,
      style: pw.TextStyle(fontSize: 8, color: color, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5));

  static pw.Widget _meta(String k, String v, PdfColor ink, PdfColor muted) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(children: [
          pw.SizedBox(width: 70, child: pw.Text(k, style: pw.TextStyle(fontSize: 9, color: muted))),
          pw.Text(v, style: pw.TextStyle(fontSize: 9, color: ink, fontWeight: pw.FontWeight.bold)),
        ]),
      );

  static pw.Widget _cell(String text, {bool bold = false, bool right = false, required PdfColor color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: pw.Text(text,
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(fontSize: bold ? 8 : 10, color: color, fontWeight: bold ? pw.FontWeight.bold : null)),
      );

  static pw.Widget _total(String k, String v, PdfColor ink, PdfColor muted) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(k, style: pw.TextStyle(fontSize: 10, color: muted)),
            pw.Text(v, style: pw.TextStyle(fontSize: 10, color: ink)),
          ],
        ),
      );
}
