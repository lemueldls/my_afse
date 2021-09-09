import "dart:async";
import "dart:math" as Math;

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:linked_scroll_controller/linked_scroll_controller.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:universal_html/parsing.dart";

import "../utils/shimmer.dart";
import "../utils/student.dart";

const cellSize = 48.0;
const dateWidth = cellSize * 2.25;

class AttendanceData {
  final List<Day> table;
  final int columns;

  const AttendanceData({
    required this.table,
    required this.columns,
  });

  factory AttendanceData.parseData(String html) {
    const colors = {
      "P": Colors.green,
      "E": Colors.grey,
      "T": Colors.orange,
      "A": Colors.red,
    };

    final rows =
        parseHtmlDocument(html).querySelectorAll("#submission tr").skip(1);

    final data =
        rows.map((row) => (row.innerText.trim().split("\n").length - 4) / 2);
    final columns = data.isNotEmpty ? data.reduce(Math.max).toInt() : 0;

    final table = rows.map((row) {
      final tds = row.querySelectorAll("td");

      final date = DateFormat("y-M-d").parse(tds.first.innerText);

      final day = tds.sublist(3, columns + 3).map((td) {
        final title = td.title!;

        if (title.isNotEmpty) {
          final split = title.split(" - ");

          final letter = td.innerText;
          final color = colors[letter]!;

          return Period(
            letter: letter,
            color: color,
            title: split[0],
            teacher: split[1],
            name: split[2],
          );
        }
      });

      return Day(date: date, data: day);
    }).toList(growable: false);

    return AttendanceData(
      table: table,
      columns: columns,
    );
  }

  @override
  toString() => table.toString();
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class Day {
  final DateTime date;
  final Iterable<Period?> data;

  const Day({required this.date, required this.data});

  @override
  toString() => "{ $date, $data }";
}

class Period {
  final String letter;
  final Color color;
  final String title;
  final String teacher;
  final String name;

  const Period({
    required this.letter,
    required this.color,
    required this.title,
    required this.teacher,
    required this.name,
  });

  @override
  toString() => "{ $title, $teacher, $name }";
}

class PeriodCell extends StatelessWidget {
  final Period? period;
  final DateTime date;

  const PeriodCell(this.period, {required this.date});

  @override
  build(context) {
    final hasPeriod = period != null;

    return Material(
      color: period?.color,
      child: InkWell(
        onTap: hasPeriod ? () => _openDialog(context) : null,
        child: Container(
          width: cellSize,
          height: cellSize,
          alignment: Alignment.center,
          child: hasPeriod
              ? Text(
                  period!.letter,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  void _openDialog(BuildContext context) => showDialog(
        context: context,
        builder: (context) {
          final data = period!;

          return AlertDialog(
            title: Text(data.title),
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
                Text(data.name),
                Row(
                  children: [
                    const Text(
                      "Teacher: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(data.teacher),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat.yMMMMEEEEd().format(date)),
                ),
              ],
            ),
          );
        },
      );
}

class TableBody extends StatefulWidget {
  final ScrollController scrollController;
  final List<Day> table;
  final int columns;

  const TableBody({
    required this.scrollController,
    required this.table,
    required this.columns,
  });

  @override
  _TableBodyState createState() => _TableBodyState();
}

class TableCell extends StatelessWidget {
  final String value;
  final double width;
  final Alignment alignment;

  const TableCell(
    this.value, {
    this.width = cellSize,
    this.alignment = Alignment.center,
  });

  @override
  build(context) => Container(
        width: width,
        height: cellSize,
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(value),
      );
}

class TableHead extends StatelessWidget {
  final ScrollController scrollController;
  final int columns;

  const TableHead({required this.scrollController, required this.columns});

  @override
  build(context) => Container(
        height: cellSize,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 1.0, color: Colors.grey),
          ),
        ),
        child: Row(
          children: [
            const TableCell("Date", width: dateWidth),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: columns,
                itemBuilder: (context, index) => TableCell(index.toString()),
              ),
            ),
          ],
        ),
      );
}

class _AttendancePageShimmer extends StatelessWidget {
  final int columns;

  const _AttendancePageShimmer({Key? key, required this.columns})
      : super(key: key);

  @override
  build(context) {
    final size = MediaQuery.of(context).size;

    final width = size.width ~/ cellSize;
    final height = size.height ~/ cellSize;

    return columns == 0
        ? const ListTile(title: CustomShimmer())
        : ListView.builder(
            itemCount: height,
            itemBuilder: (context, index) => SizedBox(
              height: cellSize,
              width: size.width,
              child: Row(
                children: [
                  const SizedBox(
                    width: dateWidth,
                    child: CustomShimmer(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: Math.min(columns, width),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => const SizedBox(
                        width: cellSize,
                        child: Center(child: CustomShimmer(width: 16.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

class _AttendancePageState extends State<AttendancePage> {
  final _refreshController = RefreshController();

  final _controllers = LinkedScrollControllerGroup();
  late final ScrollController _headController = _controllers.addAndGet();
  late final ScrollController _bodyController = _controllers.addAndGet();

  final _prefs = SharedPreferences.getInstance();

  int _columns = 15;

  late Future<AttendanceData> _futureAttendance = _fetchAttendance();

  @override
  build(context) => SmartRefresher(
        physics: const BouncingScrollPhysics(),
        controller: _refreshController,
        onRefresh: _refresh,
        child: FutureBuilder<AttendanceData>(
          future: _futureAttendance,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text("${snapshot.error}");
            if (snapshot.connectionState == ConnectionState.waiting)
              return _AttendancePageShimmer(columns: _columns);

            final data = snapshot.data!;

            final columns = data.columns;
            _saveColumns(columns);

            return columns == 0
                ? const ListTile(
                    title: Text("There is no attendance data to show."),
                  )
                : Column(
                    children: [
                      TableHead(
                        scrollController: _headController,
                        columns: columns,
                      ),
                      Expanded(
                        child: TableBody(
                          scrollController: _bodyController,
                          table: data.table,
                          columns: columns,
                        ),
                      ),
                    ],
                  );
          },
        ),
      );

  @override
  void dispose() {
    _headController.dispose();
    _bodyController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _loadColumns();
  }

  Future<AttendanceData> _fetchAttendance() async {
    final response = await http.get(
      Uri.parse(
        "https://api.jumpro.pe/attendance/student_attendance_summary/?as=html&student_id=${student.id}",
      ),
    );

    if (response.statusCode == 200)
      // If the server did return a 200 OK response,
      // then parse the HTML.
      return AttendanceData.parseData(response.body);
    else
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception("Failed to load attendance");
  }

  void _loadColumns() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => _columns = (prefs.getInt("columns") ?? _columns));
  }

  void _refresh() => setState(() {
        _futureAttendance = _fetchAttendance();

        _futureAttendance
            .then((data) => _refreshController.refreshCompleted())
            .catchError((error) => _refreshController.refreshFailed());
      });

  void _saveColumns(int columns) async {
    final prefs = await _prefs;

    await prefs.setInt("columns", _columns = columns);
  }
}

class _TableBodyState extends State<TableBody> {
  final _controllers = LinkedScrollControllerGroup();
  late final ScrollController _firstColumnController = _controllers.addAndGet();
  late final ScrollController _restColumnsController = _controllers.addAndGet();

  @override
  build(context) {
    final table = widget.table;
    final columns = widget.columns;

    final length = table.length;

    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(width: 1.0, color: Colors.grey),
            ),
          ),
          width: dateWidth,
          child: ListView.builder(
            controller: _firstColumnController,
            physics: const ClampingScrollPhysics(),
            itemCount: length,
            itemBuilder: (context, index) {
              final date = DateFormat.MMMEd().format(table[index].date);

              return TableCell(
                date,
                alignment: Alignment.centerLeft,
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: columns * cellSize,
              child: ListView.builder(
                controller: _restColumnsController,
                physics: const ClampingScrollPhysics(),
                itemCount: length,
                itemBuilder: (context, index) {
                  final row = table[index];

                  return Row(
                    children: row.data
                        .map((period) => PeriodCell(period, date: row.date))
                        .toList(growable: false),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstColumnController.dispose();
    _restColumnsController.dispose();

    super.dispose();
  }
}
