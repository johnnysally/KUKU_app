import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';

class PoultryDetailsScreen extends StatefulWidget {
  const PoultryDetailsScreen({super.key});

  @override
  State<PoultryDetailsScreen> createState() => _PoultryDetailsScreenState();
}

class _PoultryDetailsScreenState extends State<PoultryDetailsScreen> {
  late Box _flockBox;

  @override
  void initState() {
    super.initState();
    _flockBox = Hive.box('flocks');
  }

  Future<void> _confirmDelete(int index) async {
    final messenger = ScaffoldMessenger.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete flock'),
        content: const Text('Are you sure you want to delete this flock?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      await _flockBox.deleteAt(index);
      messenger.showSnackBar(const SnackBar(content: Text('Flock deleted')));
    }
  }

  void _showDetails(Map item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name'] ?? 'Flock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${item['type'] ?? '-'}'),
            Text('Count: ${item['count'] ?? '-'}'),
            Text('Avg age (weeks): ${item['avgAgeWeeks'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('Notes:'),
            Text(item['notes'] ?? '-'),
            const SizedBox(height: 8),
            Text('Recorded: ${item['createdAt'] ?? '-'}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poultry Details'), backgroundColor: AppColors.primary),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ValueListenableBuilder(
          valueListenable: _flockBox.listenable(),
          builder: (context, Box box, _) {
            if (box.isEmpty) {
              return Center(child: Text('No flocks recorded yet', style: TextStyle(color: AppColors.textDark)));
            }
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                final item = box.getAt(index) as Map? ?? {};
                return Card(
                  child: ListTile(
                    title: Text(item['name'] ?? 'Unnamed'),
                    subtitle: Text('${item['type'] ?? '-'} • ${item['count'] ?? '-'} birds'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(index),
                    ),
                    onTap: () => _showDetails(item),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
