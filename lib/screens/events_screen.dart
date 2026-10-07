import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../providers/auth_provider.dart';
import '../models/event_model.dart';
import '../widgets/create_sheet_kit.dart';

class SchoolEventsHub extends StatefulWidget {
  const SchoolEventsHub({super.key});

  @override
  State<SchoolEventsHub> createState() => _SchoolEventsHubState();
}

class _SchoolEventsHubState extends State<SchoolEventsHub> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).loadEvents();
    });
  }

  Future<void> _refreshEvents() async {
    await Provider.of<StudentProvider>(context, listen: false).loadEvents();
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 0);
    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
            final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
            final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';

            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 14,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sheetDragHandle(),
                    sheetHeader(
                      icon: Icons.event_available_rounded,
                      title: 'Create New School Event',
                      subtitle: 'Add it to the shared school calendar',
                    ),
                    const SizedBox(height: 24),
                    sheetSectionLabel('Event Title'),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: sheetFieldDecoration(
                        hint: 'e.g. Annual Sports Day 2026',
                        icon: Icons.title_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    sheetSectionLabel('Description'),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: sheetFieldDecoration(
                        hint: 'What is this event about...',
                      ),
                    ),
                    const SizedBox(height: 18),
                    sheetSectionLabel('Location / Venue'),
                    TextField(
                      controller: locationController,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: sheetFieldDecoration(
                        hint: 'e.g. Main School Auditorium',
                        icon: Icons.location_on_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    sheetSectionLabel('Schedule'),
                    sheetPickerTile(
                      icon: Icons.calendar_month_rounded,
                      label: 'EVENT DATE',
                      value: DateFormat('EEEE, MMM dd, yyyy').format(selectedDate),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: sheetPickerTile(
                            icon: Icons.access_time_rounded,
                            label: 'START TIME',
                            value: startTime.format(sheetContext),
                            onTap: () async {
                              final picked = await showTimePicker(context: sheetContext, initialTime: startTime);
                              if (picked != null) setModalState(() => startTime = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: sheetPickerTile(
                            icon: Icons.access_time_filled_rounded,
                            label: 'END TIME',
                            value: endTime.format(sheetContext),
                            onTap: () async {
                              final picked = await showTimePicker(context: sheetContext, initialTime: endTime);
                              if (picked != null) setModalState(() => endTime = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    sheetSubmitButton(
                      label: 'CREATE EVENT',
                      icon: Icons.add_circle_rounded,
                      isLoading: isCreating,
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty ||
                            descriptionController.text.trim().isEmpty ||
                            locationController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All fields are required')),
                          );
                          return;
                        }
                        setModalState(() => isCreating = true);
                        final success = await Provider.of<StudentProvider>(context, listen: false).createEvent({
                          'title': titleController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'event_date': dateStr,
                          'start_time': startStr,
                          'end_time': endStr,
                          'location': locationController.text.trim(),
                        });
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Event created successfully!' : 'Failed to create event'),
                              backgroundColor: success ? const Color(0xFF4CAF50) : Colors.redAccent,
                            ),
                          );
                        }
                      },
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.role == 'admin';

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddEventDialog,
              backgroundColor: const Color(0xFF0077BE),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Create Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Stack(
        children: [
          _buildBackgroundShapes(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Consumer<StudentProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading && provider.events.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077BE)),
                          ),
                        );
                      }

                      if (provider.error != null && provider.events.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
                                const SizedBox(height: 16),
                                Text(
                                  provider.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _refreshEvents,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0077BE),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final today = DateTime.now();
                      final todayDate = DateTime(today.year, today.month, today.day);

                      final upcomingEvents = provider.events.where((e) =>
                        e.eventDate.isAfter(todayDate) || e.eventDate.isAtSameMomentAs(todayDate)
                      ).toList();

                      final pastEvents = provider.events.where((e) =>
                        e.eventDate.isBefore(todayDate)
                      ).toList();

                      if (provider.events.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refreshEvents,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'No school events scheduled.',
                                  style: TextStyle(color: Colors.black45, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshEvents,
                        color: const Color(0xFF0077BE),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            if (upcomingEvents.isNotEmpty) ...[
                              _buildSectionTitle('Upcoming Events'),
                              ...upcomingEvents.map((event) => _buildEventCard(
                                    context,
                                    event,
                                    const Color(0xFF0077BE),
                                  )),
                              const SizedBox(height: 20),
                            ],
                            if (pastEvents.isNotEmpty) ...[
                              _buildSectionTitle('Past Records'),
                              ...pastEvents.map((event) => _buildPastRecordTile(
                                    context,
                                    event,
                                  )),
                            ],
                            const SizedBox(height: 30),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF0077BE).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          right: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: Column(
              children: [
                const Text(
                  'Events Hub',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0077BE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 15, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event, Color color) {
    final dayString = DateFormat('dd').format(event.eventDate);
    final monthString = DateFormat('MMM').format(event.eventDate).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: event, themeColor: color),
            ),
          );
        },
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayString,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.1,
                ),
              ),
              Text(
                monthString,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 12, color: Colors.black38),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: color.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildPastRecordTile(BuildContext context, EventModel event) {
    final dateStr = DateFormat('MMM dd, yyyy').format(event.eventDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: event, themeColor: Colors.grey, isPast: true),
            ),
          );
        },
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
        ),
        subtitle: Text(
          event.location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Colors.black45),
        ),
        trailing: Text(
          dateStr,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  final Color themeColor;
  final bool isPast;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.themeColor,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = "${event.startTime.substring(0, 5)} - ${event.endTime.substring(0, 5)}";
    final dateStr = DateFormat('EEEE, MMMM dd, yyyy').format(event.eventDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isPast ? 'Past Event Detail' : 'Event Details',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: themeColor.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white30, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'About this Event',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.6),
            ),
            const SizedBox(height: 24),
            if (event.whatToBring != null && event.whatToBring!.trim().isNotEmpty) ...[
              _buildDetailSection(
                icon: Icons.backpack_rounded,
                title: 'What to Bring',
                content: event.whatToBring!,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
            ],
            if (event.whatToDo != null && event.whatToDo!.trim().isNotEmpty) ...[
              _buildDetailSection(
                icon: Icons.assignment_turned_in_rounded,
                title: 'Instructions / What to Do',
                content: event.whatToDo!,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
            ],
            if (event.learningGoals != null && event.learningGoals!.trim().isNotEmpty) ...[
              _buildDetailSection(
                icon: Icons.lightbulb_rounded,
                title: 'Learning Goals',
                content: event.learningGoals!,
                color: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
