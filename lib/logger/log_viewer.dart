import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:path_pilot/backend_api/submit_log.dart';
import 'package:path_pilot/helper/dialogs.dart';
import 'package:path_pilot/logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class LogViewer extends StatefulWidget {
  final LogFile logFile;
  static final DateFormat timeFormat = DateFormat("HH:mm:ss");

  const LogViewer({super.key, required this.logFile});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Viewer"),
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  enabled: !isSubmitting,
                  onTap: () async {
                    if (isSubmitting) {
                      showSnackBar("Already sending log");
                      return;
                    }

                    final conf = await confirmDialog(context, "Send Log", "Are you sure you want to send the log to the developers?");
                    if (!conf) return;

                    isSubmitting = true;
                    await submitLog(widget.logFile);
                    isSubmitting = false;
                  },
                  child: const ListTile(
                    leading: Icon(Icons.send),
                    title: Text("Send log"),
                  ),
                ),
                PopupMenuItem(
                  child: const ListTile(
                    leading: Icon(Icons.open_in_browser),
                    title: Text("Open log file"),
                  ),
                  onTap: () async {
                    final success = await launchUrl(
                      Uri.file(widget.logFile.file.path),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!success) showSnackBar("Failed to open log file");
                  },
                ),
                PopupMenuItem(
                  child: const ListTile(
                    leading: Icon(Icons.delete),
                    title: Text("Clear log file"),
                  ),
                  onTap: () async {
                    final conf = await confirmDialog(context, "Delete Log", "Are you sure you want to clear the log file?");
                    if (!conf) return;

                    setState(() => widget.logFile.clear());
                    if (context.mounted) {
                      showSnackBar("Log file cleared");
                    }
                  },
                ),
              ];
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: widget.logFile.read(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final lines = snapshot.data;

          if (lines == null) {
            return const Center(child: Text("No data"));
          }

          if (lines.isEmpty) {
            return const Center(child: Text("No log entries"));
          }

          return GroupedListView(
            elements: lines,
            groupBy: (line) => line.date,
            groupHeaderBuilder: (msg) => ListTile(title: Text(msg.date)),
            itemComparator: (a, b) => a.time.compareTo(b.time),
            useStickyGroupSeparators: true,
            stickyHeaderBackgroundColor: const Color(0xFF202020),
            order: GroupedListOrder.DESC,
            itemBuilder: (context, line) {
              return Card(
                clipBehavior: Clip.antiAlias,
                color: line.level.color,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(line.level.icon, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${LogViewer.timeFormat.format(line.time)} - ${line.message}",
                          style: const TextStyle(fontFamily: "RobotoMono"),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: line.message));
                          showSnackBar("Copied to clipboard");
                        },
                        icon: const Icon(Icons.copy, size: 18),
                      ),
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
