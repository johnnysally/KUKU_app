import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  late Box _profileBox;
  String? _existingPin;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box('profile');
    _existingPin = _profileBox.get('appPin') as String?;
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final newPin = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (newPin.isEmpty || confirm.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter and confirm new PIN')));
      return;
    }

    if (newPin != confirm) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      return;
    }

    // If a PIN exists, verify current
    if (_existingPin != null) {
      final current = _currentController.text.trim();
      if (current.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter current PIN')));
        return;
      }
      if (current != _existingPin) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current PIN is incorrect')));
        return;
      }
    }

    await _profileBox.put('appPin', newPin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change App PIN'),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_existingPin != null) ...[
              TextField(
                controller: _currentController,
                obscureText: _obscureCurrent,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current PIN',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _newController,
              obscureText: _obscureNew,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New PIN',
                filled: true,
                fillColor: AppColors.cardBackground,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Confirm New PIN',
                filled: true,
                fillColor: AppColors.cardBackground,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _savePin,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Text('Save PIN', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
