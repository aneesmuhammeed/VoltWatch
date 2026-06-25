import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voltwatch/data/models/battery_insights.dart';
import 'package:voltwatch/data/models/battery_log.dart';

class ExportResult {
  final String filePath;
  final String mimeType;

  ExportResult({required this.filePath, required this.mimeType});
}

class ExportService {
  ExportService._();

  static Future<ExportResult> exportToPdf({
    required List<BatteryLog> logs,
    BatteryInsights? insights,
    bool includeStats = true,
  }) async {
    final pdf = pw.Document();
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/battery_report.pdf';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('VoltWatch Battery Report',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Paragraph(
            text: 'Generated: ${DateTime.now()}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          if (includeStats && insights != null) ...[
            pw.Header(level: 1, text: 'Insights'),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                ['Highest Level', '${insights.highest}%'],
                ['Lowest Level', '${insights.lowest}%'],
                ['Average Level', '${insights.average}%'],
                ['Drain Rate', '${insights.drainRatePerHour.toStringAsFixed(2)}%/hr'],
                if (insights.avgTemperature != null)
                  ['Avg Temperature', '${insights.avgTemperature!.toStringAsFixed(1)}°C'],
              ],
            ),
            pw.SizedBox(height: 16),
          ],
          pw.Header(level: 1, text: 'Battery Logs'),
          pw.TableHelper.fromTextArray(
            headers: ['Level', 'State', 'Timestamp', 'Temp'],
            data: logs.map((log) => [
              '${log.batteryLevel}%',
              log.batteryState,
              log.timestamp.toString(),
              log.temperatureCelsius != null
                  ? '${log.temperatureCelsius!.toStringAsFixed(1)}°C'
                  : '-',
            ]).toList(),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    await File(path).writeAsBytes(pdfBytes);

    return ExportResult(filePath: path, mimeType: 'application/pdf');
  }

  static Future<ExportResult> exportToJson({
    required List<BatteryLog> logs,
    BatteryInsights? insights,
    bool includeStats = true,
  }) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/battery_logs.json';

    final Map<String, dynamic> exportData = {};
    if (includeStats && insights != null) {
      exportData['insights'] = {
        'highest': insights.highest,
        'lowest': insights.lowest,
        'average': insights.average,
        'drainRatePerHour': insights.drainRatePerHour,
        if (insights.avgTemperature != null)
          'avgTemperature': insights.avgTemperature,
      };
    }
    exportData['logs'] = logs.map((l) => l.toJson()).toList();
    final content = jsonEncode(exportData);

    final file = File(path);
    await file.writeAsString(content);

    return ExportResult(filePath: path, mimeType: 'application/json');
  }

  static Future<ExportResult> exportToCsv({
    required List<BatteryLog> logs,
    BatteryInsights? insights,
    bool includeStats = true,
  }) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/battery_logs.csv';

    final List<List<dynamic>> csvData = [];
    if (includeStats && insights != null) {
      csvData.add(["--- TODAY'S INSIGHTS ---"]);
      csvData.add(['Highest Level', 'Lowest Level', 'Average Level', 'Drain Rate Per Hour (%)']);
      csvData.add([
        insights.highest,
        insights.lowest,
        insights.average,
        insights.drainRatePerHour
      ]);
      csvData.add([]);
    }
    csvData.add(['Battery Level', 'Battery State', 'Timestamp', 'Temperature (°C)']);
    for (final log in logs) {
      csvData.add([
        log.batteryLevel,
        log.batteryState,
        log.timestamp.toIso8601String(),
        log.temperatureCelsius?.toStringAsFixed(1) ?? '',
      ]);
    }
    final content = const ListToCsvConverter().convert(csvData);

    final file = File(path);
    await file.writeAsString(content);

    return ExportResult(filePath: path, mimeType: 'text/csv');
  }

  static Future<void> shareFile(ExportResult result) async {
    await Share.shareXFiles(
      [XFile(result.filePath)],
      text: 'VoltWatch Battery Analytics Export',
    );
  }
}