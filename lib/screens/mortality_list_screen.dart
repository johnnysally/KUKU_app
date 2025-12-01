import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';

class MortalityListScreen extends StatefulWidget {
  const MortalityListScreen({super.key});

  @override
  State<MortalityListScreen> createState() => _MortalityListScreenState();
}

class _MortalityListScreenState extends State<MortalityListScreen> {
  final DateFormat _dateFormat = DateFormat.yMMMd();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mortality Records'),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.background,
      body: ValueListenableBuilder(
        valueListenable: Hive.box('mortality').listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Text('No mortality records yet', style: TextStyle(color: AppColors.textDark)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: box.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = box.getAt(index) as Map?;
              if (item == null) return const SizedBox.shrink();
              final flock = (item['flock'] as String?) ?? 'Unknown flock';
              final count = (item['count'] as int?) ?? 0;
              final dateStr = (item['date'] as String?) ?? item['createdAt'] ?? '';
              String dateDisplay = '';
              try {
                dateDisplay = _dateFormat.format(DateTime.parse(dateStr));
              } catch (_) {
                dateDisplay = dateStr;
              }
              final reason = (item['reason'] as String?) ?? '';

              return Dismissible(
                key: ValueKey(box.keyAt(index)),
                background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_forever, color: Colors.white)),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  final messenger = ScaffoldMessenger.of(context);
                  await box.deleteAt(index);
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text('Record deleted')));
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(color: AppColors.primary.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text(count.toString(), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(flock, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            const SizedBox(height: 6),
                            Text('$dateDisplay • ${reason.isNotEmpty ? reason : 'No reason provided'}', style: TextStyle(color: AppColors.textDark.withAlpha(150))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppColors.primary),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await box.deleteAt(index);
                          if (!mounted) return;
                          messenger.showSnackBar(const SnackBar(content: Text('Record deleted')));
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
