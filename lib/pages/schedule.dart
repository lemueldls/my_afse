import "dart:async";
import "dart:math";

import "package:carousel_slider/carousel_slider.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:universal_html/parsing.dart";

import "../extensions/int.dart";
import "../extensions/list.dart";
import "../utils/api.dart" as api;
import "../utils/shimmer.dart";
import "../utils/student.dart";
import "../widgets/error.dart";

class Period {
  final int index;
  final String name;
  final String? start;
  final String? end;
  final List<String>? teachers;
  final String? room;

  const Period({
    required this.index,
    required this.name,
    required this.start,
    required this.end,
    required this.teachers,
    required this.room,
  });
}

class PeriodListView extends StatefulWidget {
  final List<Period> day;
  final bool today;

  const PeriodListView({
    required this.day,
    required this.today,
    final Key? key,
  }) : super(key: key);

  @override
  PeriodListViewState createState() => PeriodListViewState();
}

class PeriodListViewState extends State<PeriodListView> {
  int? _selectedIndex;

  /// Timer used to wait for the next period to highlight.
  Timer? _timer;

  @override
  Widget build(final BuildContext context) {
    final day = widget.day;
    final today = widget.today;

    if (today && day.first.start != null && day.first.end != null) {
      /// Update the currently selected period.
      void update() {
        final now = DateTime.now();

        _selectedIndex = now.isBefore(_timeToDate(day.first.start!))
            ? 0
            : day.indexWhere((final period) {
                final start = _timeToDate(period.start!);
                final end = _timeToDate(period.end!);

                if (now.isAfter(start) && now.isBefore(end)) {
                  _timer = Timer(end.difference(now), () => setState(update));

                  return true;
                }

                return false;
              });
      }

      update();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      separatorBuilder: (final context, final index) => const Divider(
        height: 0,
        indent: 16,
        endIndent: 16,
      ),
      itemCount: day.length,
      itemBuilder: (final context, final index) {
        final period = day[index];

        final selected = today && _selectedIndex == index;

        final width = MediaQuery.of(context).size.width;

        return ListTile(
          selected: selected,
          leading: Padding(
            padding: const EdgeInsets.only(top: 3.5),
            child: Text(
              period.index.toString(),
              style: selected ? null : const TextStyle(color: Colors.grey),
            ),
          ),
          title: Row(
            children: [
              // Show time for bigger screens.
              if (width >= 750 && period.start != null && period.end != null)
                SizedBox(
                  width: 200,
                  child: Text(
                    "${period.start} \u2013 ${period.end}",
                    style: selected
                        ? null
                        : TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              Flexible(child: Text(period.name)),
            ],
          ),
          trailing: Text(period.room ?? ""),
          onTap: () => _selectPeriod(period),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  void _selectPeriod(final Period period) {
    final room = period.room;
    final teachers = period.teachers;

    final hasRoom = room != null;
    final hasTeachers = teachers != null;

    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: Text(period.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${period.index.ordinal} Period"),
            if (period.start != null && period.end != null)
              Row(
                children: [
                  const Text("From "),
                  Text(
                    period.start!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(" to "),
                  Text(
                    period.end!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            if (hasRoom || hasTeachers)
              const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
            if (hasRoom)
              Row(
                children: [
                  const Text(
                    "Room: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(room),
                ],
              ),
            if (hasTeachers)
              Wrap(
                children: [
                  Text(
                    "Teacher${teachers.length > 1 ? "s" : ""}: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(teachers.join(", ")),
                ],
              ),
          ],
        ),
      ),
    );
  }

  DateTime _timeToDate(final String time) {
    final now = DateTime.now();
    final parsed = DateFormat.jm().parse(time);

    return DateTime(
      now.year,
      now.month,
      now.day,
      parsed.hour,
      // Update 3 minutes before class ends
      parsed.minute - 3,
    );
  }
}

/// Parses the schedule sheet as a HTML document
/// because I can't get any direct data from the API.
class ScheduleData {
  final List<String> times;
  final List<List<Period>> schedule;

  const ScheduleData({
    required this.times,
    required this.schedule,
  });

  factory ScheduleData.parseData(final String html) {
    final table = parseHtmlDocument(html).querySelector("table");

    /// A list of times for every period.
    final times = table!
        .getElementsByClassName("period-time-label")
        .map((final time) => time.text!)
        .toList(growable: false);

    /// A list of days.
    final schedule = <List<Period>>[];

    // A fallback list of period times.
    const fallback = [
      "8:00 AM",
      "9:00 AM",
      "10:00 AM",
      "11:00 AM",
      "12:00 PM",
      "1:00 PM",
      "1:40 PM",
      "2:20 PM",
      "3:20 PM",
      "4:20 PM",
    ];

    for (var i = 2; i < DateTime.daysPerWeek; i++) {
      final day = <Period>[];

      table
          .querySelectorAll("tr td:nth-child($i)")
          .asMap()
          .forEach((final row, final cell) {
        if (cell.className != "cell-with-data") return;

        /// Time associated with this period cell.
        /// If none matches, it will use last period's time.
        /// If [times] is empty, it will be null.
        final timeRow = times.tryGet(row) ?? times.tryGet(times.length - 1);

        /// Time of period parsed into a more readable format.
        /// Example: `["1:40 PM", "2:20 PM"]`
        final time = timeRow?.split("-").map((final time) {
              final start = int.parse(time.split(":")[0]);

              return "${time.trim()} ${start > 5 && start != 12 ? "A" : "P"}M";
            }).toList(growable: false) ??
            [fallback[row], fallback[row + 1]];

        final data = cell.text!
            .split("\n")
            .map((final text) => text.trim())
            .where((final text) => text.isNotEmpty)
            .toList(growable: false);

        final name = data[0];
        final teachers = data[1];
        final room = data.tryGet(2);

        day.add(
          Period(
            index: row,
            name: name,
            start: time[0],
            end: time[1],
            teachers: teachers == "None" ? null : teachers.split(", "),
            room: room?.split("Room ")[1] ?? room,
          ),
        );
      });

      schedule.add(day);
    }

    return ScheduleData(times: times, schedule: schedule);
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({final Key? key}) : super(key: key);

  @override
  SchedulePageState createState() => SchedulePageState();
}

class SchedulePageState extends State<SchedulePage> {
  final _refreshController = RefreshController();
  final _controller = CarouselController();

  final _prefs = SharedPreferences.getInstance();

  int _periods = 7;

  late Stream<ScheduleData> _scheduleStream = _broadcastSchedule();

  /// Timer used to switch to the current day.
  Timer? _timer;
  int _currentDay = min((DateTime.now().weekday - 1) % 6, DateTime.friday - 1);

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    const weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () => setState(() => _scheduleStream = _broadcastSchedule()),
      child: SingleChildScrollView(
        child: Align(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 750),
            child: StreamBuilder<ScheduleData>(
              stream: _scheduleStream,
              builder: (final context, final snapshot) {
                if (snapshot.hasError)
                  return ErrorCard(error: "${snapshot.error}");
                if (snapshot.connectionState == ConnectionState.waiting)
                  return _SchedulePageShimmer(periods: _periods);

                final schedule = snapshot.data!.schedule;

                _savePeriods(schedule);

                final now = DateTime.now();
                final tomorrow =
                    DateTime(now.year, now.month, now.day + 1).difference(now);

                _timer = Timer(
                  tomorrow,
                  () => setState(() => ++_currentDay),
                );

                final maxPeriods = schedule.fold<int>(
                  0,
                  (final value, final day) => max(value, day.length),
                );

                return CarouselSlider.builder(
                  carouselController: _controller,
                  options: CarouselOptions(
                    height: 72.0 + 57 * maxPeriods,
                    viewportFraction: 1,
                    initialPage: _currentDay,
                  ),
                  itemCount: schedule.length,
                  itemBuilder: (final context, final weekday, final realIndex) {
                    final today = weekday == now.weekday - 1;

                    const curve = Curves.ease;

                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: IconButton(
                                  onPressed: () =>
                                      _controller.previousPage(curve: curve),
                                  icon: const Icon(Icons.chevron_left),
                                ),
                              ),
                              Expanded(
                                flex: 0,
                                child: Text(
                                  weekdays[weekday],
                                  style: textTheme.titleLarge,
                                ),
                              ),
                              Expanded(
                                child: IconButton(
                                  onPressed: () =>
                                      _controller.nextPage(curve: curve),
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        OrientationBuilder(
                          builder: (final context, final orientation) =>
                              PeriodListView(
                            day: schedule[weekday],
                            today: today,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _loadPeriods();
  }

  Stream<ScheduleData> _broadcastSchedule() =>
      _fetchSchedule().asBroadcastStream()
        ..first
            .then((final data) => _refreshController.refreshCompleted())
            .catchError((final error) => _refreshController.refreshFailed());

  Stream<ScheduleData> _fetchSchedule() async* {
    try {
      final stream = api.getCached(
        "https://api.jumpro.pe/schedule/student_schedule/?as=html&student_id=${student.id}",
      );

      await for (final response in stream)
        yield ScheduleData.parseData(response.body);
    } on Exception {
      throw Exception("Failed to load schedule");
    }
  }

  Future<void> _loadPeriods() async {
    final prefs = await _prefs;

    final periods = prefs.getStringList("periods");
    setState(
      () => _periods =
          periods == null ? _periods : int.parse(periods[_currentDay]),
    );
  }

  Future<void> _savePeriods(final List<List<Period>> schedule) async {
    final prefs = await _prefs;

    await prefs.setStringList(
      "periods",
      schedule
          .map((final weekday) => weekday.length.toString())
          .toList(growable: false),
    );

    _periods = schedule[_currentDay].length;
  }
}

class _SchedulePageShimmer extends StatelessWidget {
  final int periods;

  const _SchedulePageShimmer({
    required this.periods,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) => Column(
        children: [
          const CustomShimmer(padding: EdgeInsets.all(28)),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            separatorBuilder: (final context, final index) => const Divider(
              height: 0,
              indent: 16,
              endIndent: 16,
            ),
            itemCount: periods,
            itemBuilder: (final context, final index) => const ListTile(
              leading: CustomShimmer(
                width: 16,
                padding: EdgeInsets.only(top: 3.5),
              ),
              title: CustomShimmer(),
              trailing: SizedBox.shrink(),
            ),
          ),
        ],
      );
}
