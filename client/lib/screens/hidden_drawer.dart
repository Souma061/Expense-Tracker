import 'package:expense_tracker/screens/help_screen.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/screens/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Hiddendrawer extends StatefulWidget {
  const Hiddendrawer({super.key});

  @override
  State<Hiddendrawer> createState() => _HiddendrawerState();
}

class _HiddendrawerState extends State<Hiddendrawer> {
  final _advancedDrawerController = AdvancedDrawerController();
  int currentIndex = 0;

  List<Widget> get _pages {
    return [
      Homescreen(advancedDrawerController: _advancedDrawerController),
      Helpandsupport(advancedDrawerController: _advancedDrawerController),
      SettingScreen(advancedDrawerController: _advancedDrawerController),
    ];
  }

  @override
  void dispose() {
    _advancedDrawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AdvancedDrawer(
      backdrop: Container(
        width: size.width,
        height: size.height,
        color: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      childDecoration: BoxDecoration(borderRadius: BorderRadius.circular(14.r)),
      controller: _advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 500),
      animateChildDecoration: false,
      rtlOpening: false,
      openRatio: 0.60,
      disabledGestures: false,
      drawer: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 22.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DrawerHeader(),
              SizedBox(height: 34.h),
              Text(
                "Menu",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 12.h),
              _DrawerTile(
                selected: currentIndex == 0,
                icon: FontAwesomeIcons.solidHouse,
                title: "Home",
                onTap: () => _selectPage(0),
              ),
              SizedBox(height: 8.h),
              _DrawerTile(
                selected: currentIndex == 1,
                icon: FontAwesomeIcons.circleQuestion,
                title: "Help & Support",
                onTap: () => _selectPage(1),
              ),
              SizedBox(height: 8.h),
              _DrawerTile(
                selected: currentIndex == 2,
                materialIcon: Icons.settings,
                title: "Settings",
                onTap: () => _selectPage(2),
              ),
              const Spacer(),
              const _DrawerFooter(),
            ],
          ),
        ),
      ),
      child: _pages[currentIndex],
    );
  }

  Future<void> _selectPage(int index) async {
    setState(() {
      currentIndex = index;
    });
    await Future.delayed(const Duration(milliseconds: 250));
    _advancedDrawerController.hideDrawer();
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 48.w,
          width: 48.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: Theme.of(context).scaffoldBackgroundColor,
            size: 27.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Spend Smart",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                "Manage your money",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final bool selected;
  final FaIconData? icon;
  final IconData? materialIcon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.selected,
    required this.title,
    required this.onTap,
    this.icon,
    this.materialIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodyLarge?.color;

    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        leading: icon != null
            ? FaIcon(icon, color: color, size: 21.sp)
            : Icon(materialIcon, color: color, size: 25.sp),
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontSize: 18.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              "Version 1.0.0",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
