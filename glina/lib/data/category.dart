import 'package:flutter/material.dart';

class Category {
  final String name;
  final String icon;
  final Color light, dark;
  const Category(this.name, this.icon, this.light, this.dark);

  Color colorOf(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;
  Color forDark(bool isDark) => isDark ? dark : light;
}

const expenseCategories = [
  Category('Еда', 'bowl', Color(0xFF2E6300), Color(0xFF9EC869)),
  Category('Кафе', 'cup', Color(0xFF8A4E32), Color(0xFFD18B74)),
  Category('Транспорт', 'bus', Color(0xFF0092D2), Color(0xFF00A7E0)),
  Category('Учёба', 'book', Color(0xFF0054B5), Color(0xFFA9B8F7)),
  Category('Подписки', 'play', Color(0xFF9F1D71), Color(0xFFFC8BCA)),
  Category('Покупки', 'bag', Color(0xFF856600), Color(0xFFEBB939)),
  Category('Другое', 'dots', Color(0xFF716861), Color(0xFFADA49B)),
];

/// Legacy income categories stay in the model for old entries; they are not
/// offered for new income.
const incomeCategories = [
  Category('Стипендия', 'cash', Color(0xFF009567), Color(0xFF00A57C)),
  Category('Другое', 'dots', Color(0xFF716861), Color(0xFFADA49B)),
];

const legacyIncome = [
  Category('Подработка', 'case', Color(0xFF0092D2), Color(0xFF00A7E0)),
  Category('Подарок', 'gift', Color(0xFF9F1D71), Color(0xFFFC8BCA)),
];

Category findCategory(String name, bool isIncome) {
  final list = isIncome
      ? [...incomeCategories, ...legacyIncome]
      : expenseCategories;
  final other = isIncome ? incomeCategories.last : expenseCategories.last;
  return list.firstWhere((c) => c.name == name, orElse: () => other);
}
