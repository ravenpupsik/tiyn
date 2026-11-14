import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;
  const Category(this.name, this.icon, this.color);
}

const expenseCategories = [
  Category('Еда', Icons.shopping_basket_rounded, Color(0xFF54B36D)),
  Category('Кафе', Icons.local_cafe_rounded, Color(0xFFD7993A)),
  Category('Транспорт', Icons.directions_bus_rounded, Color(0xFF3888D9)),
  Category('Учёба', Icons.school_rounded, Color(0xFFA367C4)),
  Category('Подписки', Icons.subscriptions_rounded, Color(0xFFD75571)),
  Category('Покупки', Icons.shopping_bag_rounded, Color(0xFF51A4B5)),
  Category('Другое', Icons.more_horiz_rounded, Color(0xFF8E8E93)),
];

const incomeCategories = [
  Category('Стипендия', Icons.account_balance_rounded, Color(0xFF51BA6D)),
  Category('Подработка', Icons.work_rounded, Color(0xFF73BAD9)),
  Category('Подарок', Icons.card_giftcard_rounded, Color(0xFFD77388)),
  Category('Другое', Icons.more_horiz_rounded, Color(0xFF8E8E93)),
];

Category findCategory(String name, bool isIncome) {
  final list = isIncome ? incomeCategories : expenseCategories;
  return list.firstWhere((c) => c.name == name, orElse: () => list.last);
}
