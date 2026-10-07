class FeeModel {
  final int id;
  final String title;
  final String? description;
  final double amount;
  final String type;
  final DateTime dueDate;
  final String? paymentStatus;
  final PaymentModel? payment;

  FeeModel({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.type,
    required this.dueDate,
    this.paymentStatus,
    this.payment,
  });

  factory FeeModel.fromJson(Map<String, dynamic> json) {
    return FeeModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      type: json['type'],
      dueDate: DateTime.parse(json['due_date']),
      paymentStatus: json['payment_status'],
      payment: json['payment'] != null
          ? PaymentModel.fromJson(json['payment'])
          : null,
    );
  }
}

class PaymentModel {
  final int id;
  final int studentId;
  final int feeId;
  final double amount;
  final String paymentMethod;
  final String transactionId;
  final String status;
  final DateTime paymentDate;

  PaymentModel({
    required this.id,
    required this.studentId,
    required this.feeId,
    required this.amount,
    required this.paymentMethod,
    required this.transactionId,
    required this.status,
    required this.paymentDate,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      studentId: json['student_id'],
      feeId: json['fee_id'],
      amount: json['amount'].toDouble(),
      paymentMethod: json['payment_method'],
      transactionId: json['transaction_id'],
      status: json['status'],
      paymentDate: DateTime.parse(json['payment_date']),
    );
  }
}
