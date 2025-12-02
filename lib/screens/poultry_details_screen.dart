import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';
import '../services/locale_service.dart';
import '../widgets/localized_text.dart';

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
        title: Text(LocaleService.instance.t('delete_flock_title')),
        content: Text(LocaleService.instance.t('delete_flock_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(LocaleService.instance.t('cancel'))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(LocaleService.instance.t('delete'))),
        ],
      ),
    );
    if (yes == true) {
      await _flockBox.deleteAt(index);
      messenger.showSnackBar(SnackBar(content: Text(LocaleService.instance.t('flock_deleted'))));
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
            Text(LocaleService.instance.t('type_label', {'value': item['type']?.toString() ?? '-'})),
            Text(LocaleService.instance.t('count_label', {'value': item['count']?.toString() ?? '-'})),
            Text(LocaleService.instance.t('avg_age_label', {'value': item['avgAgeWeeks']?.toString() ?? '-'})),
            const SizedBox(height: 8),
            Text(LocaleService.instance.t('notes_label')),
            Text(LocaleService.instance.t('recorded_label', {'value': item['createdAt']?.toString() ?? '-'}), style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: LocalizedText('poultry_details', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.primary),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ValueListenableBuilder(
          valueListenable: _flockBox.listenable(),
          builder: (context, Box box, _) {
            if (box.isEmpty) {
              return Center(child: LocalizedText('no_flocks_recorded', style: TextStyle(color: AppColors.textDark)));
            }
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                final item = box.getAt(index) as Map? ?? {};
                return Card(
                  child: ListTile(
                    title: Text(item['name'] ?? 'Unnamed'),
                    subtitle: Text('${item['type'] ?? '-'} • ${item['count'] ?? '-'} ${LocaleService.instance.t('birds')}'),
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
