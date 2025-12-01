// lib/screens/saved_tips_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';

class SavedTipsScreen extends StatelessWidget {
  const SavedTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Tips', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Box>(
          future: Hive.openBox('ai_tips'),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            final box = snap.data!;
            if (box.isEmpty) {
              return Center(child: Text('No saved tips yet', style: TextStyle(color: AppColors.textDark)));
            }
            final items = box.values.toList().reversed.toList();
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = Map<String, dynamic>.from(items[index] as Map);
                final preview = (item['tip'] as String).split('\n').first;
                final savedAt = item['savedAt'] ?? '';
                return Card(
                  color: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(savedAt.toString(), style: TextStyle(color: AppColors.textDark.withAlpha(160))),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Saved Tip'),
                          content: SingleChildScrollView(child: Text(item['tip'] ?? '')),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final key = box.keyAt(box.length - 1 - index);
                        await box.delete(key);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tip deleted')));
                      },
                    ),
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
