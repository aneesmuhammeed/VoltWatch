import 'package:flutter/material.dart';

/// Export format selection dialog for battery data export.
class ExportFormatDialog extends StatefulWidget {
  const ExportFormatDialog({super.key});

  @override
  State<ExportFormatDialog> createState() => _ExportFormatDialogState();
}

class _ExportFormatDialogState extends State<ExportFormatDialog> {
  String _selectedFormat = 'csv';
  bool _includeStats = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Battery Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Export Format',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildFormatOption('CSV (Excel/Sheets)', 'csv'),
                _buildFormatOption('JSON (Data Import)', 'json'),
                _buildFormatOption('PDF (Print)', 'pdf'),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Include Statistics'),
              subtitle: const Text('Add summary stats and analysis'),
              value: _includeStats,
              onChanged: (value) => setState(() => _includeStats = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            {'format': _selectedFormat, 'includeStats': _includeStats},
          ),
          child: const Text('Export'),
        ),
      ],
    );
  }

  Widget _buildFormatOption(String label, String value) {
    return InkWell(
      onTap: () => setState(() => _selectedFormat = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              onChanged: (val) => setState(() => _selectedFormat = val!),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}
