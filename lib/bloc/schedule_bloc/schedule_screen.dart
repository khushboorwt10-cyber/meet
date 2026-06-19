import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/schedule_bloc/schedule_bloc.dart';
import 'package:meet_easyy/bloc/schedule_bloc/schedule_event.dart';
import 'package:meet_easyy/bloc/schedule_bloc/schedule_state.dart';
import 'package:table_calendar/table_calendar.dart';


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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScheduleBloc(),
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: kSurface,
          appBar: AppBar(
            backgroundColor: kSurface,
            elevation: 0,
            title: const Text("Schedule", style: TextStyle(
                color: kTextPrimary, fontWeight: FontWeight.bold)),
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: kTextPrimary),
                onPressed: () => Navigator.pop(context)),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: kPrimary,
            onPressed: () => _showAddScheduleDialog(context),
            label: const Text("Schedule", style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              _buildCalendar(),
              Expanded(
                child: BlocBuilder<ScheduleBloc, ScheduleState>(
                  builder: (context, state) {
                    List<Map<String, String>> events = [];
                    if (state is ScheduleLoaded) {
                      final day = DateTime(_selectedDay.year,
                          _selectedDay.month, _selectedDay.day);
                      events = state.schedules[day] ?? [];
                    }
                    return events.isEmpty ? _buildEmptyState() : ListView
                        .builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      itemBuilder: (context, index) =>
                          _buildMeetingCard(events[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCalendar() =>
      Container(
        margin: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)
            ]),
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
          onDaySelected: (s, f) =>
              setState(() {
                _selectedDay = s;
                _focusedDay = f;
              }),
          calendarStyle: const CalendarStyle(
            selectedDecoration: BoxDecoration(
                color: kPrimary, shape: BoxShape.circle),
            weekendTextStyle: TextStyle(color: Colors.red),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekendStyle: TextStyle(color: Colors.red),
          ),
        ),
      );

  Widget _buildMeetingCard(Map<String, String> meeting) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.1))),
        child: ListTile(
          leading: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.videocam, color: kPrimary)),
          title: Text(meeting["title"]!, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(
              meeting["time"]!, style: TextStyle(color: kTextSecondary)),

        ),
      );

  Widget _buildEmptyState() =>
      Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_busy, size: 50, color: Colors.grey.shade300),
        const Text("No meetings scheduled",
            style: TextStyle(color: kTextSecondary))
      ]));

  void _showAddScheduleDialog(BuildContext context) {
    _titleController.clear();
    _timeController.clear();

    final bloc = BlocProvider.of<ScheduleBloc>(context);

    showDialog(
      context: context,
      builder: (_) =>
          BlocProvider.value(
            value: bloc,
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),

              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Schedule Meeting",
                        style: TextStyle(fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E))),
                    const SizedBox(height: 24),

                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Meeting Topic",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        prefixIcon: const Icon(
                            Icons.subject_rounded, color: Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _timeController,
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? t = await showTimePicker(
                            context: context, initialTime: TimeOfDay.now());
                        if (t != null) _timeController.text = t.format(context);
                      },
                      decoration: InputDecoration(
                        labelText: "Meeting Time",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        suffixIcon: const Icon(Icons.access_time_filled_rounded,
                            color: Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel", style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B57D0),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              if (_titleController.text.isNotEmpty) {
                                bloc.add(AddScheduleEvent(
                                    _selectedDay, _titleController.text,
                                    _timeController.text.isEmpty
                                        ? "Not set"
                                        : _timeController.text));
                                Navigator.pop(context);
                              }
                            },
                            child: const Text("Save Meeting", style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}