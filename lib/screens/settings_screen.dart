import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'change_pin_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _farmController = TextEditingController();
  late Box _profileBox;
  // notification sound selection: one of 'chime','bell','beep','melody','alarm'
  late String _selectedNotificationSound;

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box('profile');
    // load saved profile values
    _nameController.text = _profileBox.get('name', defaultValue: 'John Mwangi') as String;
    _farmController.text = _profileBox.get('farm', defaultValue: 'My Poultry Farm') as String;
    _notificationsEnabled = _profileBox.get('notificationsEnabled', defaultValue: true) as bool;
    _selectedNotificationSound = _profileBox.get('notificationSound', defaultValue: 'chime') as String;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Settings
            const Text(
              "Profile Settings",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 15),

            // Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Farmer Name",
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Farm Name
            TextField(
              controller: _farmController,
              decoration: InputDecoration(
                labelText: "Farm Name",
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Preferences
            const Text(
              "Preferences",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 15),

            // Notifications toggle
            SwitchListTile(
              title: const Text("Enable Notifications"),
              value: _notificationsEnabled,
              activeColor: AppColors.primary,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),

            const SizedBox(height: 25),

            // Security
            const Text(
              "Security",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 15),

            ListTile(
              leading: const Icon(Icons.lock, color: AppColors.textDark),
              title: const Text("Change App PIN", style: TextStyle(color: AppColors.textDark)),
              trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textDark),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePinScreen()),
                );
              },
            ),

            const SizedBox(height: 25),

            // Notification Sounds
            const Text(
              "Notification Sounds",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('Chime'),
              value: 'chime',
              groupValue: _selectedNotificationSound,
              activeColor: AppColors.primary,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedNotificationSound = v);
                _profileBox.put('notificationSound', v);
                // play a preview when the user selects this sound
                NotificationService.instance.previewSound(v);
              },
            ),
            RadioListTile<String>(
              title: const Text('Bell'),
              value: 'bell',
              groupValue: _selectedNotificationSound,
              activeColor: AppColors.primary,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedNotificationSound = v);
                _profileBox.put('notificationSound', v);
                NotificationService.instance.previewSound(v);
              },
            ),
            RadioListTile<String>(
              title: const Text('Beep'),
              value: 'beep',
              groupValue: _selectedNotificationSound,
              activeColor: AppColors.primary,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedNotificationSound = v);
                _profileBox.put('notificationSound', v);
                NotificationService.instance.previewSound(v);
              },
            ),
            RadioListTile<String>(
              title: const Text('Melody'),
              value: 'melody',
              groupValue: _selectedNotificationSound,
              activeColor: AppColors.primary,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedNotificationSound = v);
                _profileBox.put('notificationSound', v);
                NotificationService.instance.previewSound(v);
              },
            ),
            RadioListTile<String>(
              title: const Text('Alarm'),
              value: 'alarm',
              groupValue: _selectedNotificationSound,
              activeColor: AppColors.primary,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedNotificationSound = v);
                _profileBox.put('notificationSound', v);
                NotificationService.instance.previewSound(v);
              },
            ),
            RadioListTile<String>(
              title: const Text('Note'),
              value: 'note',
              groupValue: _selectedNotificationSound,
              activeColor: AppColors.primary,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedNotificationSound = v);
                _profileBox.put('notificationSound', v);
                NotificationService.instance.previewSound(v);
              },
            ),

            const SizedBox(height: 25),

            // Save Settings Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Save settings to local Hive profile box
                  _profileBox.put('name', _nameController.text.trim());
                  _profileBox.put('farm', _farmController.text.trim());
                  _profileBox.put('notificationsEnabled', _notificationsEnabled);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Settings saved successfully")),
                  );
                },
                child: const Text(
                  "Save Settings",
                  style: TextStyle(fontSize: 18, color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Account / Logout
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.textDark),
              title: Text(
                AuthService.instance.currentUserEmail() ?? 'Not signed in',
                style: const TextStyle(color: AppColors.textDark),
              ),
              subtitle: const Text('Account', style: TextStyle(color: AppColors.textDark)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await AuthService.instance.logout();
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
