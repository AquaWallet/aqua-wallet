import 'package:aqua/data/models/models.dart';
import 'package:aqua/data/provider/isar_database_provider.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:isar/isar.dart';

final databaseContentsProvider =
    FutureProvider.autoDispose<Map<String, List<dynamic>>>((ref) async {
  final isar = await ref.watch(storageProvider.future);
  return {
    'Transactions': await isar.transactionDbModels.where().findAll(),
    'Sideshift Orders': await isar.sideshiftOrderDbModels.where().findAll(),
    'Boltz Swaps': await isar.boltzSwapDbModels.where().findAll(),
    'Peg Orders': await isar.pegOrderDbModels.where().findAll(),
  };
});

//TODO: Add paging for items, only loads first 10
class DebugDatabaseScreen extends HookConsumerWidget {
  const DebugDatabaseScreen({super.key});

  static const routeName = '/debugDatabaseScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final databaseContents = ref.watch(databaseContentsProvider);

    return Scaffold(
      appBar: const AquaAppBar(
        title: 'Debug Database View',
        showBackButton: true,
        showActionButton: false,
      ),
      body: databaseContents.when(
        data: (contents) => ListView(
          children: contents.entries
              .map((entry) => _buildSection(context, entry.key, entry.value))
              .toList(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<dynamic> items) {
    return ExpansionTile(
      title: Text(title),
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ItemTile(item: items[index]);
          },
        ),
      ],
    );
  }
}

class ItemTile extends HookWidget {
  final dynamic item;

  const ItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);

    return ExpansionTile(
      title: Text('ID: ${item.id}'),
      onExpansionChanged: (expanded) => isExpanded.value = expanded,
      children: [
        if (isExpanded.value)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: item.toJson().entries.map<Widget>((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('${entry.value}'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
