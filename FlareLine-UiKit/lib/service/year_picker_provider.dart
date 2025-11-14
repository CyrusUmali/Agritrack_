import 'package:flutter/foundation.dart';

class YearPickerProvider with ChangeNotifier {
  int _selectedYear = DateTime.now().year;

  int get selectedYear => _selectedYear;

  void setYear(int year) {
    _selectedYear = year;
    if (kDebugMode) {
      print('Year changed to: $year');
    }
    notifyListeners();
  }
}
