import 'package:intl/intl.dart';

final NumberFormat _currencyFormatter = NumberFormat.simpleCurrency(name: 'BOB');

String formatMoney(double value) => _currencyFormatter.format(value);

String formatDate(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
