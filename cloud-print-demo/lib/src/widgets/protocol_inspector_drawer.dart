import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';

import '../models/demo_mode.dart';
import '../models/protocol_inspector.dart';

class ProtocolInspectorDrawer extends StatefulWidget {
  const ProtocolInspectorDrawer({super.key, required this.inspector});

  final ProtocolInspectorController inspector;

  @override
  State<ProtocolInspectorDrawer> createState() =>
      _ProtocolInspectorDrawerState();
}

class _ProtocolInspectorDrawerState extends State<ProtocolInspectorDrawer> {
  CloudPrinterFamily? _familyFilter;
  WireDirection? _directionFilter;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 420,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: widget.inspector,
          builder: (context, _) {
            final entries = widget.inspector
                .filtered(family: _familyFilter, direction: _directionFilter)
                .reversed
                .toList(growable: false);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '协议日志（${entries.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: '复制全部日志',
                        onPressed: entries.isEmpty
                            ? null
                            : () async {
                                final text = widget.inspector.exportAll(
                                  family: _familyFilter,
                                  direction: _directionFilter,
                                );
                                await Clipboard.setData(
                                  ClipboardData(text: text),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('协议日志已复制')),
                                );
                              },
                        icon: const Icon(Icons.copy_all_outlined),
                      ),
                      IconButton(
                        tooltip: '清空日志',
                        onPressed: widget.inspector.count == 0
                            ? null
                            : widget.inspector.clear,
                        icon: const Icon(Icons.delete_sweep_outlined),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('全部'),
                        selected: _familyFilter == null,
                        onSelected: (_) => setState(() => _familyFilter = null),
                      ),
                      for (final family in CloudPrinterFamily.values)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: FilterChip(
                            label: Text(family.tabLabel),
                            selected: _familyFilter == family,
                            onSelected: (_) => setState(
                              () => _familyFilter = _familyFilter == family
                                  ? null
                                  : family,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: SegmentedButton<WireDirection?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('全部')),
                      ButtonSegment(value: WireDirection.tx, label: Text('TX')),
                      ButtonSegment(value: WireDirection.rx, label: Text('RX')),
                    ],
                    selected: <WireDirection?>{_directionFilter},
                    onSelectionChanged: (s) =>
                        setState(() => _directionFilter = s.first),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无协议记录。\n请执行配网、查询或打印操作。',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _InspectorEntryCard(entry: entries[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InspectorEntryCard extends StatelessWidget {
  const _InspectorEntryCard({required this.entry});

  final ProtocolTrafficEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTx = entry.direction == WireDirection.tx;
    final dirColor = isTx ? scheme.primary : const Color(0xFF2E7D32);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: dirColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isTx ? 'TX' : 'RX',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: dirColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${entry.family.tabLabel} · ${entry.transport}',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                entry.formattedTimestamp,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: scheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.decodedSummary,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          SelectableText(
            entry.hexPreview,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 11,
              color: scheme.outline,
            ),
          ),
          if (entry.textPreview != null && entry.textPreview!.isNotEmpty) ...[
            const SizedBox(height: 4),
            SelectableText(
              entry.textPreview!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
