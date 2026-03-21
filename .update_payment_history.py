from pathlib import Path

path = Path(r'c:\Users\andre\Downloads\stitch\au_connect\lib\models\payment_status.dart')
text = path.read_text(encoding='utf-8')
lines = text.splitlines(keepends=True)

# Add paymentHistory list if missing
if 'paymentHistory' not in text:
    for i, line in enumerate(lines):
        if 'static PaymentStatus applicationFeeStatus' in line:
            lines.insert(i + 1, '  static final List<PaymentRecord> paymentHistory = [];\n')
            break

# Add helper methods if missing
if 'addPaymentRecord' not in text:
    end_idx = None
    for i, line in enumerate(lines):
        if 'static void updatePaymentStatus' in line:
            brace = 0
            for j in range(i, len(lines)):
                brace += lines[j].count('{')
                brace -= lines[j].count('}')
                if brace == 0 and j > i:
                    end_idx = j
                    break
            break
    if end_idx is not None:
        insert_idx = end_idx + 1
        lines.insert(
            insert_idx,
            "\n  static void addPaymentRecord(PaymentRecord record) {\n    paymentHistory.insert(0, record);\n  }\n\n  static void updatePaymentRecordStatus(String txRef, PaymentStatus status, {String? note}) {\n    final index = paymentHistory.indexWhere((r) => r.txRef == txRef);\n    if (index == -1) return;\n\n    paymentHistory[index].status = status;\n    if (note != null) {\n      paymentHistory[index].note = note;\n    }\n  }\n"
        )

path.write_text(''.join(lines), encoding='utf-8')
print('Updated payment_status.dart')
