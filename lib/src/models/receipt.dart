enum ReceiptStatus { sent, delivered, read }

extension EnumParsing on ReceiptStatus {
  String value() {
    return this.toString().split('.').last;
  }

  static ReceiptStatus fromString(String status) {
    return ReceiptStatus.values
        .firstWhere((element) => element.value() == status);
  }
}

class Receipt {
  final String recipient;
  final String messageId;
  final ReceiptStatus status;
  final DateTime timestamp;
  String _id;

  Receipt(this.recipient, this.messageId, this.status, this.timestamp);
  String get id => _id;
}
