import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

// Models
part 'models/medication.dart';
part 'models/medication_log.dart';

// Define theme colors
const primaryColor = Color(0xFF0070F3); // Vercel blue
const backgroundColor = Color(0xFF09090B);
const surfaceColor = Color(0xFF18181B);
const textColor = Color(0xFFF9FAFB);
const secondaryTextColor = Color(0xFFA1A1AA);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final appDocumentDirectory =
        await path_provider.getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDirectory.path);
  }

  // Register Hive adapters
  Hive.registerAdapter(MedicationAdapter());
  Hive.registerAdapter(MedicationLogAdapter());

  // Open Hive boxes
  await Hive.openBox<Medication>('medications');
  await Hive.openBox<MedicationLog>('medicationLogs');

  runApp(const MedTrackerApp());
}

class MedTrackerApp extends StatelessWidget {
  const MedTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedTracker',
      theme: ThemeData.dark().copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        cardColor: surfaceColor,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme.copyWith(
            bodyLarge: TextStyle(color: textColor),
            bodyMedium: TextStyle(color: secondaryTextColor),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        cardTheme: CardTheme(
          color: surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade800, width: 1),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Listen for tab changes to update the UI
    _tabController.addListener(() {
      // This forces a rebuild when tab changes to show/hide the app bar action
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format today's date for display
    final today = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(today);

    return Scaffold(
      appBar: AppBar(
        title:
            _tabController.index == 0
                ? Text(formattedDate) // Show date in title for Today tab
                : const Text('MedTracker'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TodayMedicationsTab(noteController: _noteController),
          MedicationListTab(),
          HistoryTab(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: secondaryTextColor,
        indicatorColor: primaryColor,
        tabs: const [
          Tab(icon: Icon(Icons.today), text: 'Today'),
          Tab(icon: Icon(Icons.list), text: 'Medications'),
          Tab(icon: Icon(Icons.history), text: 'History'),
        ],
      ),
      floatingActionButton:
          _tabController.index == 1
              ? FloatingActionButton(
                onPressed: () => showAddEditMedicationDialog(context),
                tooltip: 'Add Medication',
                backgroundColor: primaryColor,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  void showAddEditMedicationDialog(
    BuildContext context, {
    Medication? medication,
  }) {
    final TextEditingController nameController = TextEditingController(
      text: medication?.name ?? '',
    );
    final List<bool> daysSelected =
        medication?.daysToTake ?? List.generate(7, (_) => false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                medication == null ? 'Add Medication' : 'Edit Medication',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        hintText: 'Enter medication name',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Which days do you take this medication?',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < 7; i++)
                          FilterChip(
                            label: Text(_getDayName(i)),
                            selected: daysSelected[i],
                            onSelected: (bool selected) {
                              setState(() {
                                daysSelected[i] = selected;
                              });
                            },
                            selectedColor: primaryColor.withOpacity(0.2),
                            checkmarkColor: primaryColor,
                            backgroundColor: backgroundColor,
                            labelStyle: TextStyle(
                              color: daysSelected[i] ? primaryColor : textColor,
                              fontWeight:
                                  daysSelected[i]
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final med = Medication(
                        id:
                            medication?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        daysToTake: daysSelected,
                      );

                      final box = Hive.box<Medication>('medications');
                      box.put(med.id, med);

                      Navigator.of(context).pop();
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getDayName(int day) {
    switch (day) {
      case 0:
        return 'Mon';
      case 1:
        return 'Tue';
      case 2:
        return 'Wed';
      case 3:
        return 'Thu';
      case 4:
        return 'Fri';
      case 5:
        return 'Sat';
      case 6:
        return 'Sun';
      default:
        return '';
    }
  }
}

class TodayMedicationsTab extends StatefulWidget {
  final TextEditingController noteController;

  const TodayMedicationsTab({Key? key, required this.noteController})
    : super(key: key);

  @override
  _TodayMedicationsTabState createState() => _TodayMedicationsTabState();
}

class _TodayMedicationsTabState extends State<TodayMedicationsTab> {
  String _lastSavedNote = '';
  bool _hasUnsavedChanges = false;
  bool _isNotesExpanded = true; // Track expanded/collapsed state
  // Simple undo/redo implementation
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  String _currentText = '';

  @override
  void initState() {
    super.initState();

    // Add listener to detect changes to the note text
    widget.noteController.addListener(_onNoteChanged);

    // Initialize the last saved note value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLastSavedNote();
    });
  }

  @override
  void dispose() {
    widget.noteController.removeListener(_onNoteChanged);
    super.dispose();
  }

  void _initializeLastSavedNote() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final logsBox = Hive.box<MedicationLog>('medicationLogs');
    final todayLogs = logsBox.values.where((log) => log.date == today);

    if (todayLogs.isNotEmpty && todayLogs.first.note.isNotEmpty) {
      _lastSavedNote = todayLogs.first.note;
      widget.noteController.text = _lastSavedNote;
      _currentText = _lastSavedNote;
    }
  }

  void _onNoteChanged() {
    final currentNote = widget.noteController.text;

    // Only push to undo stack if the text actually changed
    if (_currentText != currentNote) {
      _undoStack.add(_currentText);
      _currentText = currentNote;
      // Clear redo stack when a new change is made
      _redoStack.clear();
    }

    setState(() {
      _hasUnsavedChanges = currentNote != _lastSavedNote;
    });
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      // Save current state to redo stack
      _redoStack.add(_currentText);

      // Get the previous state
      _currentText = _undoStack.removeLast();

      // Update the text controller without triggering the listener
      widget.noteController.removeListener(_onNoteChanged);
      widget.noteController.text = _currentText;
      widget.noteController.selection = TextSelection.fromPosition(
        TextPosition(offset: _currentText.length),
      );
      widget.noteController.addListener(_onNoteChanged);

      setState(() {
        _hasUnsavedChanges = _currentText != _lastSavedNote;
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      // Save current state to undo stack
      _undoStack.add(_currentText);

      // Get the next state
      _currentText = _redoStack.removeLast();

      // Update the text controller without triggering the listener
      widget.noteController.removeListener(_onNoteChanged);
      widget.noteController.text = _currentText;
      widget.noteController.selection = TextSelection.fromPosition(
        TextPosition(offset: _currentText.length),
      );
      widget.noteController.addListener(_onNoteChanged);

      setState(() {
        _hasUnsavedChanges = _currentText != _lastSavedNote;
      });
    }
  }

  void _saveNote() {
    final note = widget.noteController.text.trim();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final logsBox = Hive.box<MedicationLog>('medicationLogs');

    for (var log in logsBox.values.where((log) => log.date == today)) {
      log.note = note;
      logsBox.put(log.id, log);
    }

    setState(() {
      _lastSavedNote = note;
      _hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note saved'),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Medication>('medications').listenable(),
      builder: (context, Box<Medication> box, _) {
        final today = DateTime.now().weekday - 1; // 0-6, Monday-Sunday
        final todayMedications =
            box.values.where((med) => med.daysToTake[today]).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                    todayMedications.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 80,
                                color: secondaryTextColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No medications scheduled for today',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: todayMedications.length,
                          itemBuilder: (context, index) {
                            final med = todayMedications[index];
                            final logsBox = Hive.box<MedicationLog>(
                              'medicationLogs',
                            );
                            final today = DateFormat(
                              'yyyy-MM-dd',
                            ).format(DateTime.now());
                            final log = logsBox.values.firstWhere(
                              (log) =>
                                  log.medicationId == med.id &&
                                  log.date == today,
                              orElse:
                                  () => MedicationLog(
                                    id:
                                        DateTime.now().millisecondsSinceEpoch
                                            .toString(),
                                    medicationId: med.id,
                                    date: today,
                                    taken: false,
                                    note: '',
                                  ),
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(med.name),
                                trailing: Checkbox(
                                  value: log.taken,
                                  onChanged: (bool? value) {
                                    if (value != null) {
                                      log.taken = value;
                                      logsBox.put(log.id, log);
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
              ),
              const SizedBox(height: 16),
              // Notes card with expandable functionality
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Header row with toggle button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isNotesExpanded = !_isNotesExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.note_alt,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Notes for today',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isNotesExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Divider between header and content
                    Divider(height: 1, color: backgroundColor),
                    // Expandable content
                    if (_isNotesExpanded)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.undo,
                                    color:
                                        _undoStack.isNotEmpty
                                            ? primaryColor
                                            : secondaryTextColor.withOpacity(
                                              0.5,
                                            ),
                                  ),
                                  onPressed:
                                      _undoStack.isNotEmpty ? _undo : null,
                                  tooltip: 'Undo',
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.redo,
                                    color:
                                        _redoStack.isNotEmpty
                                            ? primaryColor
                                            : secondaryTextColor.withOpacity(
                                              0.5,
                                            ),
                                  ),
                                  onPressed:
                                      _redoStack.isNotEmpty ? _redo : null,
                                  tooltip: 'Redo',
                                ),
                              ],
                            ),
                            TextField(
                              controller: widget.noteController,
                              decoration: InputDecoration(
                                hintText: 'Write your notes here...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              maxLines: 5,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            if (_hasUnsavedChanges)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveNote,
                                  child: const Text('Save Note'),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MedicationListTab extends StatelessWidget {
  const MedicationListTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Medication>('medications').listenable(),
      builder: (context, Box<Medication> box, _) {
        if (box.isEmpty) {
          return const Center(child: Text('No medications added yet'));
        }

        return ListView.builder(
          itemCount: box.length,
          itemBuilder: (context, index) {
            final med = box.getAt(index);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(med!.name),
                subtitle: Text(_formatDays(med.daysToTake)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(context, med),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteDialog(context, med),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDays(List<bool> days) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDays = <String>[];

    for (int i = 0; i < days.length; i++) {
      if (days[i]) {
        selectedDays.add(dayNames[i]);
      }
    }

    return selectedDays.join(', ');
  }

  void _showEditDialog(BuildContext context, Medication medication) {
    final HomeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (HomeScreenState != null) {
      HomeScreenState.showAddEditMedicationDialog(
        context,
        medication: medication,
      );
    }
  }

  void _showDeleteDialog(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Medication'),
          content: Text('Are you sure you want to delete ${medication.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Hive.box<Medication>('medications').delete(medication.id);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class HistoryTab extends StatelessWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<MedicationLog>('medicationLogs').listenable(),
      builder: (context, Box<MedicationLog> logsBox, _) {
        // Create adherence data for the heatmap with integers (0-10 scale) instead of doubles
        final Map<DateTime, int> heatmapDataset = {};
        final Map<String, List<MedicationLog>> logsByDate = {};
        final medsBox = Hive.box<Medication>('medications');

        // Process logs and group by date
        for (var log in logsBox.values) {
          try {
            // Parse date string into DateTime
            final DateTime dateTime = DateFormat('yyyy-MM-dd').parse(log.date);

            // Add to dataset with initial value of 0 if not exists
            if (!heatmapDataset.containsKey(dateTime)) {
              heatmapDataset[dateTime] = 0;
            }

            // Group logs by date for details section
            if (!logsByDate.containsKey(log.date)) {
              logsByDate[log.date] = [];
            }
            logsByDate[log.date]!.add(log);

            // Update adherence value if medication was taken
            if (log.taken) {
              // Add 1 to the current value and we'll calculate percentage later
              heatmapDataset[dateTime] = heatmapDataset[dateTime]! + 1;
            }
          } catch (e) {
            // Handle date parsing errors silently
          }
        }

        // Calculate adherence value on a 0-10 scale for each day
        for (String date in logsByDate.keys) {
          try {
            final DateTime dateTime = DateFormat('yyyy-MM-dd').parse(date);
            final int total = logsByDate[date]!.length;
            final int taken =
                logsByDate[date]!.where((log) => log.taken).length;

            // Calculate adherence on a 0-10 scale
            final int adherenceScore =
                total > 0 ? ((taken / total) * 10).round() : 0;
            heatmapDataset[dateTime] = adherenceScore;
          } catch (e) {
            // Handle errors silently
          }
        }

        // Sort dates in descending order for the list view
        final sortedDates =
            logsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medication Adherence',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: surfaceColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Last 3 Months',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Row(
                            children: [
                              _buildLegendItem(Colors.red.shade300, 'Missed'),
                              const SizedBox(width: 8),
                              _buildLegendItem(
                                Colors.orange.shade300,
                                'Partial',
                              ),
                              const SizedBox(width: 8),
                              _buildLegendItem(Colors.green.shade300, 'Taken'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      HeatMap(
                        datasets: heatmapDataset,
                        startDate: DateTime.now().subtract(
                          const Duration(days: 90),
                        ),
                        endDate: DateTime.now(),
                        colorMode: ColorMode.color,
                        defaultColor: backgroundColor,
                        textColor: textColor,
                        showColorTip: false,
                        showText: true,
                        scrollable: true,
                        size: 36,
                        colorsets: {
                          0: Colors.grey.shade800, // No data
                          1: Colors.red.shade300, // 10% taken
                          4: Colors.orange.shade300, // 40% taken
                          7: Colors.lightGreen.shade300, // 70% taken
                          10: Colors.green.shade400, // 100% taken
                        },
                        onClick: (date) {
                          // Format date to match our storage format
                          final formattedDate = DateFormat(
                            'yyyy-MM-dd',
                          ).format(date);

                          // Check if we have logs for this date
                          if (logsByDate.containsKey(formattedDate)) {
                            _showDayDetailsDialog(
                              context,
                              formattedDate,
                              logsByDate[formattedDate]!,
                              medsBox,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Detailed History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child:
                    sortedDates.isEmpty
                        ? Center(
                          child: Text(
                            'No history data yet',
                            style: TextStyle(color: secondaryTextColor),
                          ),
                        )
                        : ListView.builder(
                          itemCount: sortedDates.length,
                          itemBuilder: (context, index) {
                            final date = sortedDates[index];
                            final logs = logsByDate[date]!;

                            // Format the date for display
                            final DateTime parsedDate = DateFormat(
                              'yyyy-MM-dd',
                            ).parse(date);
                            final String formattedDate = DateFormat(
                              'EEEE, MMMM d, yyyy',
                            ).format(parsedDate);

                            // Calculate adherence percentage
                            final int totalMeds = logs.length;
                            final int takenMeds =
                                logs.where((log) => log.taken).length;
                            final double adherencePercentage =
                                totalMeds > 0
                                    ? (takenMeds / totalMeds) * 100
                                    : 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: surfaceColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getAdherenceColor(
                                          adherencePercentage,
                                        ).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${adherencePercentage.toStringAsFixed(0)}% taken',
                                        style: TextStyle(
                                          color: _getAdherenceColor(
                                            adherencePercentage,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (logs.any(
                                      (log) => log.note.isNotEmpty,
                                    )) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.note_alt_outlined,
                                        size: 14,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Has notes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ...logs.map((log) {
                                          final med = medsBox.get(
                                            log.medicationId,
                                          );
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  log.taken
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color:
                                                      log.taken
                                                          ? Colors
                                                              .green
                                                              .shade400
                                                          : Colors.red.shade300,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    med?.name ??
                                                        'Unknown medication',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        if (logs.any(
                                          (log) => log.note.isNotEmpty,
                                        )) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: backgroundColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: primaryColor.withOpacity(
                                                  0.3,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Notes:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  logs
                                                      .firstWhere(
                                                        (log) =>
                                                            log.note.isNotEmpty,
                                                      )
                                                      .note,
                                                  style: TextStyle(
                                                    color: textColor,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: secondaryTextColor)),
      ],
    );
  }

  Color _getAdherenceColor(double percentage) {
    if (percentage >= 80) {
      return Colors.green.shade400;
    } else if (percentage >= 50) {
      return Colors.orange.shade400;
    } else {
      return Colors.red.shade400;
    }
  }

  void _showDayDetailsDialog(
    BuildContext context,
    String date,
    List<MedicationLog> logs,
    Box<Medication> medsBox,
  ) {
    // Format the date for display
    final DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(date);
    final String formattedDate = DateFormat('MMMM d, yyyy').format(parsedDate);

    // Calculate adherence
    final int total = logs.length;
    final int taken = logs.where((log) => log.taken).length;
    final double adherencePercentage = total > 0 ? (taken / total) * 100 : 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getAdherenceColor(
                        adherencePercentage,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${adherencePercentage.toStringAsFixed(0)}% adherence',
                      style: TextStyle(
                        color: _getAdherenceColor(adherencePercentage),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ...logs.map((log) {
                  final med = medsBox.get(log.medicationId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          log.taken ? Icons.check_circle : Icons.cancel,
                          color:
                              log.taken
                                  ? Colors.green.shade400
                                  : Colors.red.shade300,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            med?.name ?? 'Unknown medication',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (logs.any((log) => log.note.isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              color: primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Notes:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          logs.firstWhere((log) => log.note.isNotEmpty).note,
                          style: TextStyle(color: textColor, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }
}
