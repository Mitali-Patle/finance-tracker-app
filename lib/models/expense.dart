class Expense {
  final int id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final Map<int, double> shares;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.shares,
  });
}