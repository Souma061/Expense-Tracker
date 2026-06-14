import 'package:currency_picker/currency_picker.dart';
import 'package:expense_tracker/provider/add_expense_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Expensepage extends StatefulWidget {
  /// Called after a successful submit so the parent (e.g. bottom sheet) can close.
  final VoidCallback? onSubmitted;
  final DateTime dateTime;
  const Expensepage({super.key, this.onSubmitted, required this.dateTime});

  @override
  State<Expensepage> createState() => _ExpensepageState();
}

class _ExpensepageState extends State<Expensepage> {
  final formKey = GlobalKey<FormState>();

  Currency selectedCurrency = Currency(
    code: "INR",
    name: "Indian Rupee",
    symbol: "₹",
    number: 356,
    flag: '',
    decimalDigits: 0,
    namePlural: '',
    symbolOnLeft: true,
    decimalSeparator: '',
    thousandsSeparator: '',
    spaceBetweenAmountAndSymbol: true,
  );
  final TextEditingController amountController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartProvider = Provider.of<ExpenseAndIncomeChart>(context);
    return Form(
      key: formKey,
      child: Column(
        children: [
          const SizedBox(height: 5),
          TextFormField(
            controller: amountController,

            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid amount';
              }
              return null;
            },
            decoration: InputDecoration(
              errorStyle: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  width: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
              hintText: "Enter Amount",
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),

              prefixIcon: InkWell(
                onTap: () {
                  showCurrencyPicker(
                    context: context,
                    theme: CurrencyPickerThemeData(
                      flagSize: 30,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      bottomSheetHeight: 400,
                      titleTextStyle: Theme.of(context).textTheme.bodyMedium,
                      subtitleTextStyle: Theme.of(context).textTheme.bodyMedium,
                    ),
                    showFlag: true,
                    showCurrencyCode: true,
                    showCurrencyName: true,
                    favorite: ['INR', 'USD'],
                    onSelect: (Currency currency) {
                      setState(() {
                        selectedCurrency = currency;
                      });
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCurrency.flag.toString(),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${selectedCurrency.symbol} ",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: purposeController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Purpose';
              }
              return null;
            },
            decoration: InputDecoration(
              errorStyle: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  width: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
              hint: Text('Enter Purpose', style: TextStyle(fontSize: 18.5)),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await chartProvider.addIncome(
                    purpose: purposeController.text,
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    isExpense: true,
                    currencySymbol: selectedCurrency.symbol,
                    date: widget.dateTime,
                  );
                  formKey.currentState!.reset();
                  FocusScope.of(context).unfocus();
                  widget.onSubmitted?.call();
                }
              },
              child: Text(
                "Add Expense",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
