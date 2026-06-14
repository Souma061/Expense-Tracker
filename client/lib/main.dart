import 'package:expense_tracker/db/db_helper.dart';
import 'package:expense_tracker/models/init_shared_pref.dart';
import 'package:expense_tracker/provider/add_expense_chart.dart';
import 'package:expense_tracker/provider/image_provider.dart';
import 'package:expense_tracker/provider/theme_provider.dart';
import 'package:expense_tracker/screens/hidden_drawer.dart';
import 'package:expense_tracker/screens/login_screen.dart';
import 'package:expense_tracker/screens/splash_screen.dart';
import 'package:expense_tracker/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/provider/sync_provider.dart';

const Duration startupTimeout = Duration(seconds: 8);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InitSheredPref.instance.getSharedPref;
  await DBHelper.instance.database;

  final lastLogoutStr = await InitSheredPref.instance.getLastLogoutDate();
  if (lastLogoutStr != null) {
    final lastLogout = DateTime.tryParse(lastLogoutStr);
    if (lastLogout != null) {
      final difference = DateTime.now().difference(lastLogout);
      if (difference.inDays >= 60) {
        await DBHelper.instance.clearAllData();
        await InitSheredPref.instance.clearLastLogoutDate();
      }
    }
  }
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageController()),
        // Reuse the already-loaded instance — no second ThemeProvider created
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (context) => ExpenseAndIncomeChart()),
        ChangeNotifierProvider(
          create: (_) {
            final sp = SyncProvider();
            sp.startMonitoring();
            sp.performSync();
            return sp;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<String?> tokenFuture;
  @override
  void initState() {
    tokenFuture = InitSheredPref.instance.getToken().timeout(
      startupTimeout,
      onTimeout: () => null,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return ScreenUtilInit(
      designSize: Size(width, height),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeAnimationCurve: Curves.easeIn,
        title: 'Expense Tracker',

        themeMode: themeProvider.themeMode,
        darkTheme: AppTheme.darkTheme.copyWith(
          textTheme: GoogleFonts.poppinsTextTheme(AppTheme.darkTheme.textTheme),
        ),
        theme: AppTheme.lightTheme.copyWith(
          textTheme: GoogleFonts.poppinsTextTheme(
            AppTheme.lightTheme.textTheme,
          ),
        ),
        home: SafeArea(
          top: false,
          bottom: false,
          child: FutureBuilder(
            future: tokenFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Splashscreen();
              }
              if (snapshot.hasError) {
                return Loginscreen();
              }
              final token = snapshot.data;

              if (token == null) {
                return Loginscreen();
              }
              return Hiddendrawer();
            },
          ),
        ),
      ),
    );
  }
}
