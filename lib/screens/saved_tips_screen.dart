// lib/screens/saved_tips_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';
import '../widgets/localized_text.dart';
import '../services/locale_service.dart';

class SavedTipsScreen extends StatelessWidget {
  const SavedTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: LocalizedText('tips_title', style: const TextStyle(color: Colors.white)),
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
              return Center(child: LocalizedText('no_saved_tips', style: TextStyle(color: AppColors.textDark)));
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TipDetailScreen(
                            tip: item['tip'] ?? '',
                            savedAt: savedAt.toString(),
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                        final key = box.keyAt(box.length - 1 - index);
                        await box.delete(key);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocaleService.instance.t('tip_deleted'))));
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

class TipDetailScreen extends StatelessWidget {
  final String tip;
  final String savedAt;

  const TipDetailScreen({
    super.key,
    required this.tip,
    required this.savedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: LocalizedText('saved_tip', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: tip));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocaleService.instance.t('copied_to_clipboard'))));
            },
            tooltip: LocaleService.instance.t('copy'),
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
              Text(savedAt, style: TextStyle(color: AppColors.textDark.withAlpha(160), fontSize: 13)),
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
                      tip,
                      style: const TextStyle(fontSize: 18, height: 1.7, color: AppColors.textDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: LocalizedText('close'),
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
