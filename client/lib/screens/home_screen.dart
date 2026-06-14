import 'package:expense_tracker/models/chartdata.dart';
import 'package:expense_tracker/pages/expense_page.dart';
import 'package:expense_tracker/pages/income_page.dart';
import 'package:expense_tracker/provider/add_expense_chart.dart';
import 'package:expense_tracker/provider/image_provider.dart';
import 'package:expense_tracker/screens/all_transactions.dart';
import 'package:expense_tracker/screens/setting_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/flutter_percent_indicator.dart';
import 'package:provider/provider.dart';

class Homescreen extends StatefulWidget {
  final AdvancedDrawerController advancedDrawerController;
  const Homescreen({super.key, required this.advancedDrawerController});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final now = DateTime.now();
  String time = '';
  String get _currentMonth => DateFormat('yyyy-MM').format(DateTime.now());
  String? _selectedDate;

  @override
  void initState() {
    time = DateFormat('dd MMM yyyy').format(now);
    Future.microtask(() {
      // ignore: use_build_context_synchronously
      context.read<ExpenseAndIncomeChart>().searchByMonth(_currentMonth);
    });
    super.initState();
  }

  Widget build(BuildContext context) {
    final imageProvider = Provider.of<ImageController>(context);
    final image = imageProvider.imageFile;
    final chartProvider = Provider.of<ExpenseAndIncomeChart>(context);
    final list = chartProvider.list;

    final totalIncome = list.isEmpty
        ? 0.00
        : list
              .where((element) => element.isExpense == false)
              .fold(
                0.0,
                (previousValue, element) => previousValue + element.amount,
              );

    final totalExpense = list.isEmpty
        ? 0.00
        : list
              .where((element) => element.isExpense == true)
              .fold(
                0.0,
                (previousValue, element) => previousValue + element.amount,
              );

    final currencySymbol = chartProvider.list.isNotEmpty
        ? chartProvider.list.first.currencySymbol
        : '₹';

    final safeToSpend = totalIncome - totalExpense;
    final safeToSpendPercentage = totalIncome > 0
        ? (safeToSpend / totalIncome).clamp(0.0, 1.0)
        : 0.0;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;

    return InkWell(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DefaultTabController(
        length: 2,
        child: RefreshIndicator(
          displacement: 100,
          strokeWidth: 3,
          onRefresh: () async {
            setState(() {
              _selectedDate = null;
              time = DateFormat('dd MMM yyyy').format(now);
            });
            await chartProvider.searchByMonth(_currentMonth);
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {
                  widget.advancedDrawerController.showDrawer();
                },
                icon: ValueListenableBuilder<AdvancedDrawerValue>(
                  valueListenable: widget.advancedDrawerController,
                  builder: (_, value, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Semantics(
                        label: 'Menu',
                        onTapHint: 'expand drawer',
                        child: FaIcon(
                          key: ValueKey<bool>(value.visible),
                          value.visible
                              ? FontAwesomeIcons.xmark
                              : FontAwesomeIcons.bars,
                          color: Theme.of(context).colorScheme.primary,
                          size: 27.sp,
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20.00),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(23.r),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 23.r,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: image != null ? FileImage(image) : null,
                      child: image == null
                          ? Icon(
                              Icons.person,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              size: 25.sp,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
              title: InkWell(
                onTap: () => _selectTime(context),
                child: Text(time),
              ),
              centerTitle: true,
              bottom: TabBar(
                dividerColor: Colors.transparent,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  Tab(
                    child: Text(
                      'Income',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Expense',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child:
                  Column(
                    children: [
                      // Income / Expense form tabs
                      Container(
                        padding: const EdgeInsets.only(
                          top: 20,
                          left: 20,
                          right: 20,
                        ),
                        height: 319,
                        width: double.infinity,
                        child: TabBarView(
                          children: [const Incomepage(), const Expensepage()],
                        ),
                      ),

                      // Summary + circular indicator
                      Container(
                        padding: const EdgeInsets.all(15),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Column(
                          spacing: 40,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    leading: Container(
                                      height: 35,
                                      width: 35,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_upward,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    title: Text(
                                      "Income",
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '$currencySymbol ${totalIncome.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    leading: Container(
                                      height: 35,
                                      width: 35,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_downward,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    title: Text(
                                      "Expense",
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '$currencySymbol ${totalExpense.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            CircularPercentIndicator(
                              radius: 150.0,
                              lineWidth: 40.0,
                              animation: true,
                              animationDuration: 1200,
                              circularStrokeCap: CircularStrokeCap.round,
                              percent: safeToSpendPercentage,
                              center: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Safe to Spend",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "$currencySymbol ${safeToSpend.toStringAsFixed(2)}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "$daysLeft days left",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).inputDecorationTheme.fillColor!,
                              progressColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),

                      // Recent transactions header
                      Container(
                        padding: const EdgeInsets.all(15),
                        height: 80,
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Recent Transactions",
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontSize: 21.sp),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _seeAllTransactions(currencySymbol),
                              child: Text(
                                "See All",
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontSize: 18.sp,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Recent list with swipe-to-delete
                      _RecentTransactionList(
                        list: _selectedDate != null
                            ? chartProvider.list
                                  .where((e) => e.date == _selectedDate)
                                  .toList()
                            : chartProvider.list,
                        currencySymbol: currencySymbol,
                        onDelete: (id) => context
                            .read<ExpenseAndIncomeChart>()
                            .deleteItem(id),
                      ),
                    ],
                  ).animate().fadeIn(
                    curve: Curves.easeIn,
                    duration: const Duration(milliseconds: 350),
                  ),
            ),

          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final datetime = await showDatePicker(
      barrierColor: Colors.black45,
      context: context,
      firstDate: DateTime(1980),
      lastDate: DateTime(2200),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.secondary,
              onPrimary: Colors.black,
              onSurface: Theme.of(context).colorScheme.secondary,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              headerBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
              headerForegroundColor: Theme.of(context).colorScheme.primary,
              dayForegroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.primaryContainer,
              ),
              yearForegroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (datetime != null) {
      setState(() {
        _selectedDate = datetime.toString().split(' ')[0];
        time = DateFormat('dd MMM yyyy').format(datetime);
      });
    }
  }

  void _seeAllTransactions(String symbol) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AllTransaction(currencySymbol: symbol),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
      ),
    );
    // Restore home screen state when returning
    if (mounted) {
      setState(() {
        _selectedDate = null;
        time = DateFormat('dd MMM yyyy').format(now);
      });
      await context.read<ExpenseAndIncomeChart>().searchByMonth(_currentMonth);
    }
  }
}

// ── Recent Transaction List ──────────────────────────────────────────────────

class _RecentTransactionList extends StatelessWidget {
  final List<Chartdata> list;
  final String currencySymbol;
  final void Function(String id) onDelete;

  const _RecentTransactionList({
    required this.list,
    required this.currencySymbol,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sortedList = [...list]..sort((a, b) => b.date.compareTo(a.date));
    final recentList = sortedList.take(6).toList();

    if (recentList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Center(
          child: Text(
            "No transactions yet",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentList.length,
      itemBuilder: (context, index) {
        final item = recentList[index];
        final date = DateTime.parse(item.date);
        final formattedDate = DateFormat('MMM dd, yyyy').format(date);

        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Delete Transaction"),
                content: const Text(
                  "Are you sure you want to delete this transaction?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) { if (item.id != null) onDelete(item.id!); },
          child: ListTile(
            subtitle: Text(formattedDate),
            leading: Container(
              height: 35,
              width: 35,
              decoration: BoxDecoration(
                color: item.isExpense
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                fontWeight: FontWeight.bold,
              ),
            ),
            title: Text(
              item.purpose,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '$currencySymbol ${item.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
