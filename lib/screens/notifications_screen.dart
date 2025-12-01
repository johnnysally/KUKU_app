import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';
import '../theme/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  DateTime? _scheduled;
  late Box _notifBox;

  @override
  void initState() {
    super.initState();
    _notifBox = Hive.box('notifications');
    // initialize notification plugin
    NotificationService.instance.init();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    // ignore: use_build_context_synchronously
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    // ignore: use_build_context_synchronously
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!mounted) return;
    setState(() => _scheduled = dt);
  }

  Future<void> _schedule() async {
    if (_titleController.text.trim().isEmpty || _scheduled == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter title and schedule time')));
      return;
    }
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    await NotificationService.instance.scheduleNotification(id, title, body.isEmpty ? 'Reminder' : body, _scheduled!);
    // persist metadata
    _notifBox.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledAt': _scheduled!.toIso8601String(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder scheduled')));
    setState(() {
      _titleController.clear();
      _bodyController.clear();
      _scheduled = null;
    });
  }

  Future<void> _cancel(int id, int index) async {
    await NotificationService.instance.cancel(id);
    await _notifBox.deleteAt(index);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title', filled: true, fillColor: AppColors.cardBackground),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(labelText: 'Body (optional)', filled: true, fillColor: AppColors.cardBackground),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _scheduled == null ? 'No time selected' : df.format(_scheduled!),
                    style: TextStyle(color: AppColors.textDark),
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickDateTime,
                  child: const Text('Pick'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _schedule,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Schedule Reminder')),
            ),
            const SizedBox(height: 20),
            const Text('Scheduled Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _notifBox.listenable(),
                builder: (context, box, _) {
                  if (_notifBox.isEmpty) return Center(child: Text('No reminders', style: TextStyle(color: AppColors.textDark)));
                  return ListView.builder(
                    itemCount: _notifBox.length,
                    itemBuilder: (context, index) {
                      final Map item = _notifBox.getAt(index) as Map;
                      final id = item['id'] as int;
                      final title = item['title'] as String;
                      final body = item['body'] as String?;
                      final scheduledAt = DateTime.parse(item['scheduledAt'] as String);
                      return Card(
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text('${df.format(scheduledAt)}\n${body ?? ''}'),
                          isThreeLine: body != null && body.isNotEmpty,
                          trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _cancel(id, index)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
