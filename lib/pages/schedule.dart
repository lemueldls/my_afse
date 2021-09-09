import "dart:async";
import "dart:math" as Math;

import "package:carousel_slider/carousel_slider.dart";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:universal_html/parsing.dart";

import "../extensions/brightness.dart";
import "../extensions/int.dart";
import "../extensions/list.dart";
import "../utils/shimmer.dart";
import "../utils/student.dart";

class Period {
  final int index;
  final String name;
  final String start;
  final String end;
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
    Key? key,
    required this.day,
    required this.today,
  }) : super(key: key);

  @override
  _PeriodListViewState createState() => _PeriodListViewState();
}

class ScheduleData {
  final List<String> times;
  final List<List<Period>> schedule;

  const ScheduleData({required this.times, required this.schedule});

  factory ScheduleData.parseData(String html) {
    final table = parseHtmlDocument(html).querySelector("table");

    final times = table!
        .getElementsByClassName("period-time-label")
        .map((time) => time.text!)
        .toList(growable: false);

    final List<List<Period>> schedule = [];

    for (int i = 2; i < DateTime.daysPerWeek; i++) {
      final List<Period> day = [];

      table
          .querySelectorAll("tr td:nth-child($i)")
          .asMap()
          .forEach((row, cell) {
        if (cell.className != "cell-with-data") return;

        final time = times[row].split("-").map((time) {
          final start = int.parse(time.split(":")[0]);

          return "${time.trim()} ${start > 5 && start != 12 ? "A" : "P"}M";
        }).toList(growable: false);

        final data = cell.text!
            .split("\n")
            .map((text) => text.trim())
            .where((text) => text.isNotEmpty)
            .toList(growable: false);

        final name = data[0];
        final teachers = data[1];
        final room = data.tryGet(2);

        day.add(Period(
          index: row,
          name: name,
          start: time[0],
          end: time[1],
          teachers: teachers == "None" ? null : teachers.split(", "),
          room: room?.split("Room ")[1] ?? room,
        ));
      });

      schedule.add(day);
    }

    return ScheduleData(times: times, schedule: schedule);
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _PeriodListViewState extends State<PeriodListView> {
  int? _selectedIndex;

  final List<Timer> _timers = [];

  @override
  build(context) {
    final day = widget.day;
    final today = widget.today;

    final theme = Theme.of(context);
    final selectedColor = theme.primaryColorBrightness.text;
    final selectedTileColor = theme.primaryColor;

    const empty = SizedBox.shrink();

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      separatorBuilder: (context, index) => const Divider(
        height: 1.0,
        indent: 16.0,
        endIndent: 16.0,
      ),
      itemCount: day.length,
      itemBuilder: (context, index) {
        final period = day[index];

        if (today) {
          final start = _timeToDate(period.start);
          final end = _timeToDate(period.end);

          update({init = false}) {
            final now = DateTime.now();

            if (now.isAfter(end)) return;

            if (now.isAfter(start))
              init
                  ? _selectedIndex = index
                  : setState(() => _selectedIndex = index);
            else
              _timers.add(Timer(start.difference(now), update));
          }

          update(init: true);
        }

        final selected = today && _selectedIndex == index;

        final width = MediaQuery.of(context).size.width;

        return ListTileTheme(
          selectedColor: selectedColor,
          selectedTileColor: selectedTileColor,
          child: ListTile(
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
                width >= 750.0
                    ? SizedBox(
                        width: 200.0,
                        child: Text(
                          "${period.start} – ${period.end}",
                          style: selected
                              ? null
                              : TextStyle(color: Colors.grey.shade400),
                        ),
                      )
                    : empty,
                Flexible(child: Text(period.name)),
              ],
            ),
            trailing: Text(period.room ?? ""),
            onTap: () => _selectPeriod(period),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (var timer in _timers) {
      timer.cancel();
    }

    super.dispose();
  }

  void _selectPeriod(Period period) {
    final room = period.room;
    final teachers = period.teachers;

    final hasRoom = room != null;
    final hasTeachers = teachers != null;

    const empty = SizedBox.shrink();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(period.name),
        contentPadding: const EdgeInsets.only(
          left: 24.0,
          top: 8.0,
          right: 24.0,
          bottom: 24.0,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${period.index.ordinal} Period"),
            Row(
              children: [
                const Text("From "),
                Text(
                  period.start,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(" to "),
                Text(
                  period.end,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            hasRoom || hasTeachers
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 4.0))
                : empty,
            hasRoom
                ? Row(
                    children: [
                      const Text(
                        "Room: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(room!),
                    ],
                  )
                : empty,
            hasTeachers
                ? Wrap(
                    children: [
                      Text(
                        "Teacher${teachers!.length > 1 ? "s" : ""}: ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(teachers.join(", ")),
                    ],
                  )
                : empty,
          ],
        ),
      ),
    );
  }

  DateTime _timeToDate(String time) {
    final now = DateTime.now();
    final parsed = DateFormat.jm().parse(time);

    return DateTime(
      now.year,
      now.month,
      now.day,
      parsed.hour,
      parsed.minute - 3,
    );
  }
}

class _SchedulePageShimmer extends StatelessWidget {
  final int periods;

  const _SchedulePageShimmer({Key? key, required this.periods})
      : super(key: key);

  @override
  build(context) => Column(
        children: [
          const CustomShimmer(padding: EdgeInsets.all(28.0)),
          const Divider(height: 1.0),
          ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            separatorBuilder: (context, index) => const Divider(
              height: 1.0,
              indent: 16.0,
              endIndent: 16.0,
            ),
            itemCount: periods,
            itemBuilder: (context, index) => const ListTile(
              leading: CustomShimmer(
                width: 16.0,
                height: 16.0,
                padding: EdgeInsets.only(top: 3.5),
              ),
              title: CustomShimmer(),
              trailing: SizedBox.shrink(),
            ),
          )
        ],
      );
}

class _SchedulePageState extends State<SchedulePage> {
  final _refreshController = RefreshController();
  final _controller = CarouselController();

  final _prefs = SharedPreferences.getInstance();

  int _periods = 8;

  late Future<ScheduleData> _futureSchedule = _fetchSchedule();

  Timer? _timer;
  int _currentDay = Math.min(DateTime.now().weekday, DateTime.friday) - 1;

  @override
  build(context) {
    final height = MediaQuery.of(context).size.height - kToolbarHeight - 31.0;

    const weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

    final title = Theme.of(context).textTheme.headline6;

    return SmartRefresher(
      physics: const BouncingScrollPhysics(),
      controller: _refreshController,
      onRefresh: _refresh,
      child: Align(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 750.0),
          child: FutureBuilder<ScheduleData>(
            future: _futureSchedule,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("${snapshot.error}");
              if (snapshot.connectionState == ConnectionState.waiting)
                return _SchedulePageShimmer(periods: _periods);

              final schedule = snapshot.data!.schedule;

              _savePeriods(schedule);

              final now = DateTime.now();
              final tommorrow =
                  DateTime(now.year, now.month, now.day + 1).difference(now);

              _timer = Timer(
                tommorrow,
                () => setState(() => ++_currentDay),
              );

              return CarouselSlider.builder(
                carouselController: _controller,
                options: CarouselOptions(
                  height: height,
                  viewportFraction: 1.0,
                  initialPage: _currentDay,
                ),
                itemCount: schedule.length,
                itemBuilder: (context, weekday, _realIndex) {
                  final today = weekday == _currentDay;

                  const curve = Curves.ease;

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                                style: title,
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
                      const Divider(height: 1.0),
                      PeriodListView(
                        day: schedule[weekday],
                        today: today,
                      ),
                    ],
                  );
                },
              );
            },
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

  Future<ScheduleData> _fetchSchedule() async {
    final response = await http.get(
      Uri.parse(
        "https://api.jumpro.pe/schedule/student_schedule/?as=html&student_id=${student.id}",
      ),
    );

    if (response.statusCode == 200)
      // If the server did return a 200 OK response,
      // then parse the HTML.
      return ScheduleData.parseData(response.body);
    else
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception("Failed to load schedule");
  }

  void _loadPeriods() async {
    final prefs = await _prefs;

    final periods = prefs.getStringList("periods");
    setState(
      () => _periods =
          periods == null ? _periods : int.parse(periods[_currentDay]),
    );
  }

  void _refresh() => setState(() {
        _futureSchedule = _fetchSchedule();

        _futureSchedule
            .then((data) => _refreshController.refreshCompleted())
            .catchError((error) => _refreshController.refreshFailed());
      });

  void _savePeriods(List<List<Period>> schedule) async {
    final prefs = await _prefs;

    await prefs.setStringList(
      "periods",
      schedule
          .map((weekday) => weekday.length.toString())
          .toList(growable: false),
    );

    _periods = schedule[_currentDay].length;
  }
}
