import 'package:expense_tracker/db/db_helper.dart';
import 'package:expense_tracker/models/init_shared_pref.dart';
import 'package:expense_tracker/provider/image_provider.dart';
import 'package:expense_tracker/provider/theme_provider.dart';
import 'package:expense_tracker/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class SettingScreen extends StatefulWidget {
  final AdvancedDrawerController advancedDrawerController;

  const SettingScreen({super.key, required this.advancedDrawerController});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: "Preferences"),

            _SettingTile(
              icon: Icons.palette_outlined,
              title: "Theme",
              subtitle: "Light, Dark, or System Default",
              onTap: () {
                _showThemeDialog(context);
              },
            ),

            _SettingTile(
              icon: Icons.sync,
              title: "Sync Data",
              subtitle: "Keep your records updated",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sync feature is active")),
                );
              },
            ),

            SizedBox(height: 20.h),
            _SectionTitle(title: "Account"),

            _SettingTile(
              icon: Icons.person_outline,
              title: "Profile",
              subtitle: "Manage your account details",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),

            _SettingTile(
              icon: Icons.delete_forever_outlined,
              title: "Clear Data",
              subtitle: "Manually delete local transactions",
              iconColor: Colors.redAccent,
              onTap: () {
                _showClearDataDialog(context);
              },
            ),

            SizedBox(height: 20.h),
            _SectionTitle(title: "About"),

            _SettingTile(
              icon: Icons.info_outline,
              title: "App Version",
              subtitle: "1.0.0",
              onTap: () {},
            ),

            _SettingTile(
              icon: Icons.logout,
              title: "Logout",
              subtitle: "Sign out from your account",
              iconColor: Colors.redAccent,
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text("Select Theme"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                title: "Light",
                selected: themeProvider.themeMode == ThemeMode.light,
                onTap: () {
                  themeProvider.toggleTheme('light');
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                title: "Dark",
                selected: themeProvider.themeMode == ThemeMode.dark,
                onTap: () {
                  themeProvider.toggleTheme('dark');
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                title: "System Default",
                selected: themeProvider.themeMode == ThemeMode.system,
                onTap: () {
                  themeProvider.toggleTheme('system');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text(
            "Are you sure you want to logout?\n\nYour local data will remain on this device for 2 months. To clear it manually, use the 'Clear Data' button in settings.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await InitSheredPref.instance.logOut();

                if (!context.mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => Loginscreen()),
                );
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Clear Local Data"),
          content: const Text(
            "Are you sure you want to permanently delete all local transactions from this device?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await DBHelper.instance.clearAllData();

                if (!context.mounted) return;

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Local data cleared successfully"),
                  ),
                );
              },
              child: const Text(
                "Clear",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(title),
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _userId = "Not available";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ImageController>(context, listen: false).pickImage();
    });
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = await InitSheredPref.instance.getUserId();
    final name = await InitSheredPref.instance.getProfileName();
    final email = await InitSheredPref.instance.getProfileEmail();

    if (!mounted) return;

    setState(() {
      _userId = userId ?? "Not available";
      _nameController.text = name ?? "Spend Smart User";
      _emailController.text = email ?? "user@example.com";
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = Provider.of<ImageController>(context);
    final image = imageProvider.imageFile;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 62.r,
                    backgroundColor: Theme.of(
                      context,
                    ).inputDecorationTheme.fillColor,
                    backgroundImage: image != null ? FileImage(image) : null,
                    child: image == null
                        ? Icon(
                            Icons.person,
                            size: 58.sp,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  IconButton.filled(
                    onPressed: () {
                      _showImagePicker(context, imageProvider);
                    },
                    icon: const Icon(Icons.camera_alt),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            SizedBox(height: 14.h),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.badge_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text("User ID"),
                subtitle: Text(_userId),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_outlined),
                label: const Text("Save Profile"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context, ImageController imageProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () async {
                  await imageProvider.pickFromCamera();

                  if (!context.mounted) return;

                  Navigator.pop(context);
                },
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
              ),
              ListTile(
                onTap: () async {
                  await imageProvider.pickFromGallery();

                  if (!context.mounted) return;

                  Navigator.pop(context);
                },
                leading: const Icon(Icons.photo),
                title: const Text("Gallery"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    await InitSheredPref.instance.setProfileName(_nameController.text.trim());
    await InitSheredPref.instance.setProfileEmail(_emailController.text.trim());

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile saved")));
  }
}
