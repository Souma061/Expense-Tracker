import 'package:expense_tracker/db/db_helper.dart';
import 'package:expense_tracker/models/chartdata.dart';
import 'package:expense_tracker/models/init_shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ExpenseAndIncomeChart extends ChangeNotifier {
  List<Chartdata> _list = [];
  List<Chartdata> get list => _list;

  /// Tracks the last month filter so addIncome knows whether to append.
  String? _currentMonth;

  Future<String?> _userId() async {
    return await InitSheredPref.instance.getUserId();
  }

  String _now() {
    final n = DateTime.now();
    return '${n.year}-${_pad(n.month)}-${_pad(n.day)} ${_pad(n.hour)}:${_pad(n.minute)}:${_pad(n.second)}';
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  // READ ALL
  Future<void> loadData() async {
    _list = await DBHelper.instance.getAllData(userId: await _userId());
    notifyListeners();
  }

  /// Insert a new income or expense.
  /// Only appends to [_list] if the new item belongs to the active month filter,
  /// so viewing a past month doesn't get polluted with today's new entries.
  Future<void> addIncome({
    required String purpose,
    required double amount,
    required String currencySymbol,
    required bool isExpense,
    required DateTime date,
  }) async {
    final now = _now();
    final nowDate = date; // Use the provided date instead of DateTime.now()
    final dateStr = nowDate.toIso8601String().split('T')[0]; // 'yyyy-MM-dd'

    Chartdata data = Chartdata(
      id: const Uuid().v4(),
      purpose: purpose,
      amount: amount,
      currencySymbol: currencySymbol,
      isExpense: isExpense,
      date: dateStr,
      userId: await _userId(),
      updatedAt: now,
    );

    await DBHelper.instance.insertData(data);

    // Only add to the live list if it matches the current month filter
    final itemMonth = dateStr.substring(0, 7); // 'yyyy-MM'
    if (_currentMonth == null || itemMonth == _currentMonth) {
      _list.add(data);
    }
    notifyListeners();
  }

  // SEARCH BY DATE
  Future<void> searchByDate(String date) async {
    final data = await DBHelper.instance.searchByDate(date, userId: await _userId());
    _list = data;
    notifyListeners();
  }

  Future<void> searchByMonth(String month) async {
    _currentMonth = month;
    final data = await DBHelper.instance.searchByMonth(month, userId: await _userId());
    _list = data;
    notifyListeners();
  }

  // DELETE DATA
  Future<void> deleteItem(String id) async {
    await DBHelper.instance.deleteData(id);
    _list.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
