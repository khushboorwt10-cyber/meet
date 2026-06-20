import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/new_meet_bloc/new_meet_Screen.dart';
import 'package:meet_easyy/bloc/schedule_bloc/schedule_bloc.dart';
import 'package:meet_easyy/bloc/schedule_bloc/schedule_event.dart';
import 'package:meet_easyy/bloc/schedule_bloc/schedule_state.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

const Color kPrimary = Color(0xFF0B57D0);
const Color kSurface = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF1E293B);
const Color kTextSecondary = Color(0xFF64748B);

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late ScheduleBloc _scheduleBloc;
  String? _editingRoomId;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scheduleBloc = ScheduleBloc();
    _scheduleBloc.add(GetScheduleEvent());
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    
    // Set default time to 1 hour from now
    final now = DateTime.now();
    _selectedTime = TimeOfDay(
      hour: now.hour + 1 >= 24 ? 23 : now.hour + 1,
      minute: now.minute,
    );
    // Don't format time here - will be done in build or didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set time controller text here after context is ready
    _timeController.text = _selectedTime.format(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _scheduleBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _scheduleBloc,
      child: Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          backgroundColor: kSurface,
          elevation: 0,
          title: const Text(
            "Schedule",
            style: TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: kPrimary),
              onPressed: () {
                _scheduleBloc.add(GetScheduleEvent());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Refreshing schedules..."),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kPrimary,
          onPressed: () => _showAddScheduleDialog(context),
          label: const Text(
            "Schedule",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
        ),
        body: Column(
          children: [
            _buildCalendar(),
            Expanded(
              child: BlocBuilder<ScheduleBloc, ScheduleState>(
                builder: (context, state) {
                  if (state is ScheduleLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: kPrimary,
                      ),
                    );
                  }

                  if (state is ScheduleLoaded) {
                    final events = state.meetings.where((meeting) {
                      return meeting.scheduledDate.year == _selectedDay.year &&
                          meeting.scheduledDate.month == _selectedDay.month &&
                          meeting.scheduledDate.day == _selectedDay.day;
                    }).toList();

                    if (events.isEmpty) {
                      return _buildEmptyState(_selectedDay);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final meeting = events[index];
                        return _buildMeetingCard(meeting);
                      },
                    );
                  }

                  if (state is ScheduleError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _scheduleBloc.add(GetScheduleEvent());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Retry",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildEmptyState(_selectedDay);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() => Container(
        margin: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
            )
          ],
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2023),
          lastDay: DateTime.utc(2030),
          focusedDay: _focusedDay,
          daysOfWeekHeight: 30,
          calendarFormat: CalendarFormat.month,
          rowHeight: 50,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerMargin: EdgeInsets.zero,
          ),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: const CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: kPrimary,
              shape: BoxShape.circle,
            ),
            weekendTextStyle: TextStyle(color: Colors.red),
            todayDecoration: BoxDecoration(
              color: kPrimary,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: Colors.white),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekendStyle: TextStyle(color: Colors.red),
          ),
        ),
      );

  Widget _buildMeetingCard(MeetingModel meeting) {
    final bool canStart = meeting.canStart;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: meeting.status == 'upcoming' 
              ? Colors.blue.withOpacity(0.3) 
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              meeting.status == 'upcoming' 
                  ? Icons.schedule 
                  : Icons.play_circle_filled,
              color: meeting.status == 'upcoming' ? kPrimary : Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Title and Subtitle - Expanded to take available space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meeting.topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      meeting.formattedTime,
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (meeting.status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: meeting.status == 'upcoming' 
                              ? Colors.blue.shade100 
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          meeting.status.toUpperCase(),
                          style: TextStyle(
                            color: meeting.status == 'upcoming' 
                                ? Colors.blue.shade800 
                                : Colors.green.shade800,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Trailing Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (meeting.description.isNotEmpty)
                Tooltip(
                  message: meeting.description,
                  child: Icon(
                    Icons.info_outline,
                    color: kTextSecondary,
                    size: 18,
                  ),
                ),
              if (canStart)
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: () => _startMeeting(context, meeting.roomId),
                  tooltip: 'Start Meeting',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  iconSize: 20,
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: kTextSecondary),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditScheduleDialog(context, meeting);
                  } else if (value == 'delete') {
                    _showDeleteConfirmationDialog(context, meeting.roomId);
                  } else if (value == 'start') {
                    _startMeeting(context, meeting.roomId);
                  }
                },
                itemBuilder: (context) => [
                  if (canStart)
                    const PopupMenuItem(
                      value: 'start',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text('Start Meeting', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: kPrimary, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DateTime date) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 50,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              "No meetings on ${date.day}/${date.month}/${date.year}",
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap + to schedule a meeting",
              style: TextStyle(
                color: kTextSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  void _showMeetingDetails(BuildContext context, MeetingModel meeting) {
    final bool canStart = meeting.canStart;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          meeting.topic,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: kTextSecondary),
                const SizedBox(width: 8),
                Text(
                  meeting.formattedDate,
                  style: TextStyle(color: kTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: kTextSecondary),
                const SizedBox(width: 8),
                Text(
                  meeting.formattedTime,
                  style: TextStyle(color: kTextSecondary),
                ),
              ],
            ),
            if (meeting.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.description, size: 18, color: kTextSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meeting.description,
                      style: TextStyle(color: kTextSecondary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.video_call, size: 18, color: kTextSecondary),
                const SizedBox(width: 8),
                Text(
                  "Room ID: ${meeting.roomId}",
                  style: TextStyle(
                    color: kTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (canStart)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _startMeeting(context, meeting.roomId);
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text("Start Meeting Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditScheduleDialog(context, meeting);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("Edit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _startMeeting(BuildContext context, String roomId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kPrimary),
      ),
    );

    _scheduleBloc.add(StartMeetingEvent(roomId: roomId));
    
    BlocListener<ScheduleBloc, ScheduleState>(
      listener: (context, state) {
        Navigator.pop(context);

        if (state is MeetingStarted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => NewMeetingScreen(
              
              ),
            ),
          );
        } else if (state is ScheduleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to start meeting: ${state.message}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(),
    );
  }

  void _showAddScheduleDialog(BuildContext context) {
    _titleController.clear();
    _timeController.clear();
    _descriptionController.clear();
    _editingRoomId = null;
    
    // Set default time to 1 hour from now
    final now = DateTime.now();
    _selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    );
    _selectedTime = TimeOfDay(
      hour: now.hour + 1 >= 24 ? 23 : now.hour + 1,
      minute: now.minute,
    );
    
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _timeController.text = _selectedTime.format(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildScheduleDialog(
        context,
        title: "Schedule Meeting",
        buttonText: "Save Meeting",
        onSave: () {
          if (_titleController.text.isNotEmpty) {
            final scheduledDateTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );

            // Check if the selected date/time is in the future
            final now = DateTime.now();
            if (scheduledDateTime.isBefore(now)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please select a future date and time!"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            _scheduleBloc.add(
              AddScheduleEvent(
                topic: _titleController.text,
                description: _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : "Meeting scheduled",
                scheduledDate: scheduledDateTime,
              ),
            );

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Meeting scheduled successfully!"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please enter a meeting topic"),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, MeetingModel meeting) {
    _titleController.text = meeting.topic;
    _descriptionController.text = meeting.description;
    _selectedTime = TimeOfDay(
      hour: meeting.scheduledDate.hour,
      minute: meeting.scheduledDate.minute,
    );
    _selectedDate = meeting.scheduledDate;
    _timeController.text = meeting.formattedTime;
    _dateController.text = meeting.formattedDate;
    _editingRoomId = meeting.roomId;

    setState(() {
      _selectedDay = meeting.scheduledDate;
      _focusedDay = meeting.scheduledDate;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildScheduleDialog(
        context,
        title: "Edit Meeting",
        buttonText: "Update Meeting",
        isEditing: true,
        onSave: () {
          if (_titleController.text.isNotEmpty) {
            final scheduledDateTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );

            // Check if the selected date/time is in the future
            final now = DateTime.now();
            if (scheduledDateTime.isBefore(now)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please select a future date and time!"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            _scheduleBloc.add(
              UpdateScheduleEvent(
                roomId: _editingRoomId!,
                topic: _titleController.text,
                description: _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : "Meeting scheduled",
                scheduledDate: scheduledDateTime,
              ),
            );

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Meeting updated successfully!"),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please enter a meeting topic"),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildScheduleDialog(
    BuildContext context, {
    required String title,
    required String buttonText,
    required VoidCallback onSave,
    bool isEditing = false,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit : Icons.event_note,
                    color: kPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title Field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Meeting Topic",
                  hintText: "Enter meeting title",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.subject_rounded,
                    color: kPrimary,
                    size: 20,
                  ),
                  labelStyle: const TextStyle(fontSize: 13),
                  hintStyle: const TextStyle(fontSize: 13),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            
            // Date and Time Row
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate.isAfter(DateTime.now()) 
                              ? _selectedDate 
                              : DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now().add(const Duration(days: 1)),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: kPrimary,
                                  onPrimary: Colors.white,
                                  onSurface: kTextPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                            _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Date",
                        hintText: "Select date",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: kPrimary,
                          size: 16,
                        ),
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: kTextSecondary,
                          size: 16,
                        ),
                        labelStyle: const TextStyle(fontSize: 13),
                        hintStyle: const TextStyle(fontSize: 13),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _timeController,
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? t = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: kPrimary,
                                  onPrimary: Colors.white,
                                  onSurface: kTextPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (t != null) {
                          final now = DateTime.now();
                          final selectedDateTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            t.hour,
                            t.minute,
                          );
                          
                          if (selectedDateTime.isBefore(now)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select a future time!"),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          setState(() {
                            _selectedTime = t;
                            _timeController.text = t.format(context);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Time",
                        hintText: "Select time",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.access_time,
                          color: kPrimary,
                          size: 16,
                        ),
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: kTextSecondary,
                          size: 16,
                        ),
                        labelStyle: const TextStyle(fontSize: 13),
                        hintStyle: const TextStyle(fontSize: 13),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description Field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Description (Optional)",
                  hintText: "Add meeting description",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.description,
                    color: kPrimary,
                    size: 20,
                  ),
                  labelStyle: const TextStyle(fontSize: 13),
                  hintStyle: const TextStyle(fontSize: 13),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: onSave,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isEditing ? Icons.update : Icons.save,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String roomId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Delete Meeting",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: const Text(
          "Are you sure you want to delete this meeting? This action cannot be undone.",
          style: TextStyle(
            color: kTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _scheduleBloc.add(DeleteScheduleEvent(roomId: roomId));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Meeting deleted successfully!"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:${minute.toString().padLeft(2, '0')} $amPm';
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:meet_easyy/bloc/schedule_bloc/schedule_bloc.dart';
// import 'package:meet_easyy/bloc/schedule_bloc/schedule_event.dart';
// import 'package:meet_easyy/bloc/schedule_bloc/schedule_state.dart';
// import 'package:table_calendar/table_calendar.dart';


// const Color kPrimary = Color(0xFF0B57D0);
// const Color kSurface = Color(0xFFF8FAFC);
// const Color kTextPrimary = Color(0xFF1E293B);
// const Color kTextSecondary = Color(0xFF64748B);



// class ScheduleScreen extends StatefulWidget {
//   const ScheduleScreen({super.key});

//   @override
//   State<ScheduleScreen> createState() => _ScheduleScreenState();
// }

// class _ScheduleScreenState extends State<ScheduleScreen> {
//   DateTime _selectedDay = DateTime.now();
//   DateTime _focusedDay = DateTime.now();
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _timeController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => ScheduleBloc(),
//       child: Builder(builder: (context) {
//         return Scaffold(
//           backgroundColor: kSurface,
//           appBar: AppBar(
//             backgroundColor: kSurface,
//             elevation: 0,
//             title: const Text("Schedule", style: TextStyle(
//                 color: kTextPrimary, fontWeight: FontWeight.bold)),
//             leading: IconButton(
//                 icon: const Icon(Icons.arrow_back, color: kTextPrimary),
//                 onPressed: () => Navigator.pop(context)),
//           ),
//           floatingActionButton: FloatingActionButton.extended(
//             backgroundColor: kPrimary,
//             onPressed: () => _showAddScheduleDialog(context),
//             label: const Text("Schedule", style: TextStyle(
//                 color: Colors.white, fontWeight: FontWeight.bold)),
//             icon: const Icon(Icons.add, color: Colors.white),
//           ),
//           body: Column(
//             children: [
//               _buildCalendar(),
//               Expanded(
//                 child:BlocBuilder<ScheduleBloc, ScheduleState>(
//   builder: (context, state) {

//     if (state is ScheduleLoading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     if (state is ScheduleLoaded) {

//       final events = state.meetings.where((meeting) {

//         return meeting.scheduledDate.year ==
//                 _selectedDay.year &&
//             meeting.scheduledDate.month ==
//                 _selectedDay.month &&
//             meeting.scheduledDate.day ==
//                 _selectedDay.day;
//       }).toList();

//       if (events.isEmpty) {
//         return _buildEmptyState();
//       }

//       return ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: events.length,
//         itemBuilder: (context, index) {

//           final meeting = events[index];

//           return _buildMeetingCard({
//             "title": meeting.topic,
//             "time":
//                 "${meeting.scheduledDate.hour}:${meeting.scheduledDate.minute.toString().padLeft(2, '0')}"
//           });
//         },
//       );
//     }

//     return _buildEmptyState();
//   },
// )
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }

//   Widget _buildCalendar() =>
//       Container(
//         margin: const EdgeInsets.all(26),
//         decoration: BoxDecoration(color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             boxShadow: [
//               BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)
//             ]),
//         child: TableCalendar(
//           firstDay: DateTime.utc(2023),
//           lastDay: DateTime.utc(2030),
//           focusedDay: _focusedDay,
//           daysOfWeekHeight: 30,
//           calendarFormat: CalendarFormat.month,

//           rowHeight: 50,

//           headerStyle: const HeaderStyle(
//             formatButtonVisible: false,
//             titleCentered: true,
//             headerMargin: EdgeInsets.zero,
//           ),

//           selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//           onDaySelected: (s, f) =>
//               setState(() {
//                 _selectedDay = s;
//                 _focusedDay = f;
//               }),
//           calendarStyle: const CalendarStyle(
//             selectedDecoration: BoxDecoration(
//                 color: kPrimary, shape: BoxShape.circle),
//             weekendTextStyle: TextStyle(color: Colors.red),
//           ),
//           daysOfWeekStyle: const DaysOfWeekStyle(
//             weekendStyle: TextStyle(color: Colors.red),
//           ),
//         ),
//       );

//   Widget _buildMeetingCard(Map<String, String> meeting) =>
//       Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.blue.withOpacity(0.1))),
//         child: ListTile(
//           leading: Container(padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(color: kPrimary.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12)),
//               child: const Icon(Icons.videocam, color: kPrimary)),
//           title: Text(meeting["title"]!, style: const TextStyle(
//               fontWeight: FontWeight.bold, fontSize: 16)),
//           subtitle: Text(
//               meeting["time"]!, style: TextStyle(color: kTextSecondary)),

//         ),
//       );

//   Widget _buildEmptyState() =>
//       Center(child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(Icons.event_busy, size: 50, color: Colors.grey.shade300),
//         const Text("No meetings scheduled",
//             style: TextStyle(color: kTextSecondary))
//       ]));

//   void _showAddScheduleDialog(BuildContext context) {
//     _titleController.clear();
//     _timeController.clear();

//     final bloc = BlocProvider.of<ScheduleBloc>(context);

//     showDialog(
//       context: context,
//       builder: (_) =>
//           BlocProvider.value(
//             value: bloc,
//             child: Dialog(
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(28)),
//               insetPadding: const EdgeInsets.symmetric(horizontal: 20),

//               child: Container(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("Schedule Meeting",
//                         style: TextStyle(fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF1E1E1E))),
//                     const SizedBox(height: 24),

//                     TextField(
//                       controller: _titleController,
//                       decoration: InputDecoration(
//                         labelText: "Meeting Topic",
//                         filled: true,
//                         fillColor: Colors.grey.shade100,
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: BorderSide.none),
//                         prefixIcon: const Icon(
//                             Icons.subject_rounded, color: Colors.blueAccent),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     TextField(
//                       controller: _timeController,
//                       readOnly: true,
//                       onTap: () async {
//                         TimeOfDay? t = await showTimePicker(
//                             context: context, initialTime: TimeOfDay.now());
//                         if (t != null) _timeController.text = t.format(context);
//                       },
//                       decoration: InputDecoration(
//                         labelText: "Meeting Time",
//                         filled: true,
//                         fillColor: Colors.grey.shade100,
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: BorderSide.none),
//                         suffixIcon: const Icon(Icons.access_time_filled_rounded,
//                             color: Colors.blueAccent),
//                       ),
//                     ),
//                     const SizedBox(height: 32),

//                     // Actions
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: const Text("Cancel", style: TextStyle(
//                                 color: Colors.grey,
//                                 fontWeight: FontWeight.w600)),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF0B57D0),
//                               shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(16)),
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                             ),
//                         onPressed: () {

//   if (_titleController.text.isNotEmpty) {

//     bloc.add(
//       AddScheduleEvent(
//         topic: _titleController.text,
//         description: "Daily progress discussion",
//         scheduledDate: _selectedDay,
//       ),
//     );

//     Navigator.pop(context);
//   }
// },
//                             child: const Text("Save Meeting", style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold)),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//     );
//   }
// }