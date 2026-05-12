part of '../../main.dart';

class _LogList extends StatelessWidget {
  const _LogList({
    required this.emptyText,
    required this.entries,
    this.bottomPadding = 16,
  });

  final String emptyText;
  final List<EmapiDemoLogEntry> entries;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _LogCard(entry: entries[index]);
      },
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.title, required this.entries});

  final String title;
  final List<EmapiDemoLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, subtitle: '${entries.length} 条记录'),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text(
              '暂无',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final entry in entries.take(20)) ...[
              _LogCard(entry: entry),
              const Divider(height: 16),
            ],
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.entry});

  final EmapiDemoLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes = entry.bytes;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(entry.title, style: theme.textTheme.titleSmall),
              ),
              if (bytes != null)
                Text(
                  '${bytes.length} bytes',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(entry.message),
          if (bytes != null) ...[
            const SizedBox(height: 10),
            _HexPreview(bytes: bytes),
          ],
        ],
      ),
    );
  }
}

class _HexPreview extends StatefulWidget {
  const _HexPreview({required this.bytes});

  final Uint8List bytes;

  @override
  State<_HexPreview> createState() => _HexPreviewState();
}

class _HexPreviewState extends State<_HexPreview> {
  int bytesPerLine = 32;
  bool breakOnCrLf = false;
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _formatHex(
      widget.bytes,
      bytesPerLine: bytesPerLine,
      breakOnCrLf: breakOnCrLf,
    );
    final copyText = _formatHex(
      widget.bytes,
      bytesPerLine: bytesPerLine,
      breakOnCrLf: breakOnCrLf,
      maxBytes: widget.bytes.length,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _HexControls(
                    bytesPerLine: bytesPerLine,
                    breakOnCrLf: breakOnCrLf,
                    onBytesPerLineChanged: (value) {
                      setState(() {
                        bytesPerLine = value;
                        breakOnCrLf = false;
                      });
                    },
                    onBreakOnCrLfChanged: (value) {
                      setState(() {
                        breakOnCrLf = value;
                      });
                    },
                  ),
                ),
                IconButton(
                  tooltip: '复制 Hex',
                  onPressed: () => _copyHex(context, copyText),
                  icon: const Icon(Icons.copy_all),
                ),
                IconButton(
                  tooltip: expanded ? '收起 Hex' : '展开 Hex',
                  onPressed: () => setState(() => expanded = !expanded),
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: expanded ? 320 : 96),
              child: SingleChildScrollView(
                child: SelectableText(
                  preview,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyHex(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Hex 已复制')));
  }
}

class _HexControls extends StatelessWidget {
  const _HexControls({
    required this.bytesPerLine,
    required this.breakOnCrLf,
    required this.onBytesPerLineChanged,
    required this.onBreakOnCrLfChanged,
  });

  final int bytesPerLine;
  final bool breakOnCrLf;
  final ValueChanged<int> onBytesPerLineChanged;
  final ValueChanged<bool> onBreakOnCrLfChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _HexChip(
          label: '16',
          selected: !breakOnCrLf && bytesPerLine == 16,
          onTap: () => onBytesPerLineChanged(16),
        ),
        _HexChip(
          label: '32',
          selected: !breakOnCrLf && bytesPerLine == 32,
          onTap: () => onBytesPerLineChanged(32),
        ),
        _HexChip(
          label: '0D0A 换行',
          selected: breakOnCrLf,
          onTap: () => onBreakOnCrLfChanged(!breakOnCrLf),
        ),
      ],
    );
  }
}

class _HexChip extends StatelessWidget {
  const _HexChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      backgroundColor: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      onPressed: onTap,
    );
  }
}

const int _maxHexPreviewBytes = 4096;

String _formatHex(
  Uint8List bytes, {
  required int bytesPerLine,
  required bool breakOnCrLf,
  int maxBytes = _maxHexPreviewBytes,
}) {
  if (bytes.isEmpty) {
    return '';
  }
  final length = math.min(bytes.length, maxBytes);
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    if (i > 0) {
      final prev = bytes[i - 1];
      final prevPrev = i > 1 ? bytes[i - 2] : null;
      if (breakOnCrLf && prevPrev == 0x0D && prev == 0x0A) {
        buffer.write('\n');
      } else if (!breakOnCrLf && i % bytesPerLine == 0) {
        buffer.write('\n');
      } else {
        buffer.write(' ');
      }
    }
    buffer.write(bytes[i].toRadixString(16).padLeft(2, '0').toUpperCase());
  }
  if (bytes.length > length) {
    buffer.write('\n... truncated ${bytes.length - length} bytes');
  }
  return buffer.toString();
}
