// lib/screens/feeding_programs_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';

class FeedingProgramsScreen extends StatelessWidget {
  const FeedingProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeding Programs', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Box>(
          future: Hive.openBox('feed_programs'),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            final box = snap.data!;
            if (box.isEmpty) {
              return Center(
                child: Text('No saved feeding programs yet', style: TextStyle(color: AppColors.textDark)),
              );
            }
            final items = box.values.toList().reversed.toList();
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = Map<String, dynamic>.from(items[index] as Map);
                final preview = (item['program'] as String).split('\n').first;
                final meta = '${item['flock'] ?? ''} • ${item['feedType'] ?? ''}';
                return Card(
                  color: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(meta, style: TextStyle(color: AppColors.textDark.withAlpha(160))),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProgramDetailScreen(
                            title: 'Feeding Program',
                            meta: meta,
                            program: item['program'] ?? '',
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final key = box.keyAt(box.length - 1 - index);
                        await box.delete(key);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program deleted')));
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

class ProgramDetailScreen extends StatelessWidget {
  final String title;
  final String meta;
  final String program;

  const ProgramDetailScreen({
    super.key,
    required this.title,
    required this.meta,
    required this.program,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: program));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
            },
            tooltip: 'Copy',
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta, style: TextStyle(color: AppColors.textDark.withAlpha(180), fontSize: 14)),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      program,
                      style: const TextStyle(fontSize: 18, height: 1.7, color: AppColors.textDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
