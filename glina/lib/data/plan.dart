/// Planned expense: money reserved but not yet spent. Does not change the
/// balance, only the free amount.
class Plan {
  final String id;
  final String title;
  final int amount;
  final String category;
  final DateTime? due;

  const Plan({
    required this.id,
    required this.title,
    required this.amount,
    this.category = '',
    this.due,
  });

  String get displayTitle =>
      title.isNotEmpty ? title : (category.isNotEmpty ? category : 'План');

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'due': due?.toIso8601String(),
  };

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    id: j['id'] as String,
    title: (j['title'] ?? '') as String,
    amount: j['amount'] as int,
    category: (j['category'] ?? '') as String,
    due: j['due'] == null ? null : DateTime.parse(j['due'] as String),
  );

  static int compare(Plan a, Plan b) {
    if (a.due != null && b.due != null) return a.due!.compareTo(b.due!);
    if (a.due != null) return -1;
    if (b.due != null) return 1;
    return a.id.compareTo(b.id);
  }
}
