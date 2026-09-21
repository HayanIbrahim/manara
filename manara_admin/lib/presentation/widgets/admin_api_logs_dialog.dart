import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_logger.dart';
import '../../core/theme/app_colors.dart';

class AdminApiLogsDialog extends StatefulWidget {
  const AdminApiLogsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AdminApiLogsDialog(),
    );
  }

  @override
  State<AdminApiLogsDialog> createState() => _AdminApiLogsDialogState();
}

class _AdminApiLogsDialogState extends State<AdminApiLogsDialog> {
  bool _onlyErrors = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blueAccent;
      case 'POST':
        return Colors.purpleAccent;
      case 'PUT':
      case 'PATCH':
        return Colors.orangeAccent;
      case 'DELETE':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) return Colors.grey;
    if (statusCode >= 200 && statusCode < 300) return AppColors.success;
    if (statusCode >= 300 && statusCode < 400) return Colors.cyan;
    if (statusCode >= 400 && statusCode < 500) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: ApiLogStore.instance,
      builder: (context, _) {
        final logs = ApiLogStore.instance.logs;
        final filteredLogs = logs.where((l) {
          if (_onlyErrors && !l.isError) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matchesUrl = l.url.toLowerCase().contains(q);
            final matchesMethod = l.method.toLowerCase().contains(q);
            final matchesStatus = (l.statusCode?.toString() ?? '').contains(q);
            final matchesError = (l.errorMessage?.toLowerCase() ?? '').contains(q);
            final matchesBody = (l.requestBody?.toString().toLowerCase() ?? '').contains(q) ||
                (l.responseBody?.toString().toLowerCase() ?? '').contains(q);
            return matchesUrl || matchesMethod || matchesStatus || matchesError || matchesBody;
          }
          return true;
        }).toList();

        final errorCount = ApiLogStore.instance.errorCount;

        return Dialog(
          backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 920,
              maxHeight: 740,
              minWidth: 600,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.terminal_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'API Network & Error Inspector',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Live observability for all backend HTTP transactions and error responses',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Copy all button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_all_rounded, size: 16),
                        label: const Text('Export Logs'),
                        onPressed: logs.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: ApiLogStore.instance.exportLogsAsText()));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('All API logs copied to clipboard!')),
                                );
                              },
                      ),
                      const SizedBox(width: 10),
                      // Clear button
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                        tooltip: 'Clear Logs',
                        onPressed: logs.isEmpty ? null : () => ApiLogStore.instance.clear(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Search and Filters Bar
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search URL, status, request or response payload...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      FilterChip(
                        selected: !_onlyErrors,
                        label: Text('All (${logs.length})'),
                        onSelected: (_) => setState(() => _onlyErrors = false),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _onlyErrors,
                        avatar: errorCount > 0
                            ? const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error)
                            : null,
                        label: Text(
                          'Errors Only ($errorCount)',
                          style: TextStyle(
                            color: errorCount > 0 ? AppColors.error : null,
                            fontWeight: errorCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onSelected: (_) => setState(() => _onlyErrors = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),

                  // Logs List
                  Expanded(
                    child: filteredLogs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 48,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _onlyErrors
                                      ? 'No API errors recorded! All requests succeeded.'
                                      : 'No API logs found.',
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredLogs.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final log = filteredLogs[index];
                              return _ApiLogTile(
                                log: log,
                                isDark: isDark,
                                methodColor: _getMethodColor(log.method),
                                statusColor: _getStatusColor(log.statusCode),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ApiLogTile extends StatefulWidget {
  final ApiLogEntry log;
  final bool isDark;
  final Color methodColor;
  final Color statusColor;

  const _ApiLogTile({
    required this.log,
    required this.isDark,
    required this.methodColor,
    required this.statusColor,
  });

  @override
  State<_ApiLogTile> createState() => _ApiLogTileState();
}

class _ApiLogTileState extends State<_ApiLogTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final isDark = widget.isDark;

    return Container(
      color: log.isError
          ? AppColors.error.withValues(alpha: isDark ? 0.08 : 0.04)
          : Colors.transparent,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Method badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.methodColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.methodColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      log.method,
                      style: TextStyle(
                        color: widget.methodColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      log.statusCode != null ? '${log.statusCode}' : 'PENDING',
                      style: TextStyle(
                        color: widget.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // URL
                  Expanded(
                    child: Text(
                      log.url,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: log.isError ? FontWeight.bold : FontWeight.normal,
                        color: log.isError ? AppColors.error : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Duration & Time
                  if (log.durationMs != null) ...[
                    Text(
                      '${log.durationMs}ms',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    log.formattedTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText(
                        'Full Endpoint: ${log.url}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        tooltip: 'Copy Request & Response',
                        onPressed: () {
                          final text =
                              '${log.method} ${log.url}\nStatus: ${log.statusCode}\nRequest: ${log.requestBody}\nResponse: ${log.responseBody}\nError: ${log.errorMessage}';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Log details copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                  if (log.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              'Error: ${log.errorMessage}',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (log.requestBody != null) ...[
                    const SizedBox(height: 10),
                    const Text('Request Body:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.grey.shade100).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        '${log.requestBody}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ],
                  if (log.responseBody != null) ...[
                    const SizedBox(height: 10),
                    const Text('Response Body / Payload:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.grey.shade100).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        '${log.responseBody}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
