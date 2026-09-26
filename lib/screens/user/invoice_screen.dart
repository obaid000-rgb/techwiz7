import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../services/invoice_service.dart';
import '../../theme/app_theme.dart';

/// On-screen invoice for an order, with PDF share/download and print.
/// Generated automatically from the order — nothing extra is stored.
class InvoiceScreen extends StatefulWidget {
  final OrderModel order;
  final String customerName;
  final String customerEmail;

  const InvoiceScreen({
    super.key,
    required this.order,
    required this.customerName,
    required this.customerEmail,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String failMessage) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMessage)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Invoice', style: AppTheme.orbitron(size: 13)),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _paper(o),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(
                                () => InvoiceService.instance.share(o,
                                    customerName: widget.customerName,
                                    customerEmail: widget.customerEmail),
                                'Could not create the PDF. Try again.',
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                      label: Text('DOWNLOAD / SHARE PDF',
                          style: AppTheme.orbitron(size: 10, color: Colors.white, weight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              () => InvoiceService.instance.printInvoice(o,
                                  customerName: widget.customerName,
                                  customerEmail: widget.customerEmail),
                              'Could not open the print dialog.',
                            ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.cyan),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.print_rounded, color: AppTheme.cyan, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// White "paper" invoice so it reads like a real document.
  Widget _paper(OrderModel o) {
    const ink = Color(0xFF111827);
    const muted = Color(0xFF6B7280);
    const line = Color(0xFFE5E7EB);
    TextStyle t(double s, {Color c = ink, FontWeight w = FontWeight.w400}) =>
        GoogleFonts.inter(fontSize: s, color: c, fontWeight: w);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 24)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.cyan]),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kStoreName.toUpperCase(),
                          style: GoogleFonts.orbitron(
                              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                      const SizedBox(height: 2),
                      Text(kStoreTagline, style: t(10, c: Colors.white70)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('INVOICE',
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    Text(o.invoiceNumber, style: t(10, c: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BILLED TO', style: t(9, c: muted, w: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(widget.customerName.isEmpty ? 'Customer' : widget.customerName,
                              style: t(14, w: FontWeight.w700)),
                          if (widget.customerEmail.isNotEmpty)
                            Text(widget.customerEmail, style: t(12, c: muted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _meta('Order', o.displayNumber, t, muted),
                        _meta('Issued', InvoiceService.date(o.createdAt), t, muted),
                        _meta('Status', o.status, t, muted),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: const Color(0xFFF3F0FF),
                  child: Row(
                    children: [
                      Expanded(child: Text('ITEM', style: t(9, c: muted, w: FontWeight.w700))),
                      SizedBox(width: 36, child: Text('QTY', textAlign: TextAlign.right, style: t(9, c: muted, w: FontWeight.w700))),
                      SizedBox(width: 80, child: Text('AMOUNT', textAlign: TextAlign.right, style: t(9, c: muted, w: FontWeight.w700))),
                    ],
                  ),
                ),
                for (final item in o.items)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: line))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: t(13, w: FontWeight.w600)),
                              Text('${InvoiceService.money(item.price)} each', style: t(11, c: muted)),
                            ],
                          ),
                        ),
                        SizedBox(width: 36, child: Text('${item.quantity}', textAlign: TextAlign.right, style: t(13))),
                        SizedBox(
                          width: 80,
                          child: Text(InvoiceService.money(item.lineTotal),
                              textAlign: TextAlign.right, style: t(13, w: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Transform.rotate(
                      angle: -0.12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green.shade700, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text('PAID',
                                style: GoogleFonts.orbitron(
                                    color: Colors.green.shade700, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                            Text('SIMULATED', style: t(7, c: Colors.green.shade700, w: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Subtotal  ${InvoiceService.money(o.subtotal)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t(12, c: muted)),
                          const SizedBox(height: 4),
                          Text('TOTAL', style: t(10, c: muted, w: FontWeight.w700)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(InvoiceService.money(o.total),
                                style: GoogleFonts.orbitron(
                                    color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: line),
                Text('Generated automatically for a simulated purchase. No payment was taken and no items will be shipped.',
                    style: t(10, c: muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(String k, String v, TextStyle Function(double, {Color c, FontWeight w}) t, Color muted) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 56, child: Text(k, style: t(11, c: muted))),
            Text(v, style: t(11, w: FontWeight.w700)),
          ],
        ),
      );
}
