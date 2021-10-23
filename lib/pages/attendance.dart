import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:linked_scroll_controller/linked_scroll_controller.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:universal_html/parsing.dart";

import "../utils/constants.dart";
import "../utils/shimmer.dart";
import "../utils/student.dart";
import "../widgets/error.dart";

const cellSize = 48.0;
const dateWidth = cellSize * 2.25;

class AttendanceData {
  final List<Day> table;
  final int columns;

  const AttendanceData({
    required final this.table,
    required final this.columns,
  });

  factory AttendanceData.parseData(final String html) {
    const colors = {
      "P": Colors.green,
      "E": Colors.grey,
      "T": Colors.orange,
      "A": Colors.red,
    };

    final rows =
        parseHtmlDocument(html).querySelectorAll("#submission tr").skip(1);

    final data = rows
        .map((final row) => (row.innerText.trim().split("\n").length - 4) / 2);
    final columns = data.isNotEmpty ? data.reduce(max).toInt() : 0;

    final table = rows.map((final row) {
      final tds = row.querySelectorAll("td");

      final date = DateFormat("y-M-d").parse(tds.first.innerText);

      final day = tds.sublist(3, columns + 3).map((final td) {
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
  const AttendancePage({final Key? key}) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class Day {
  final DateTime date;
  final Iterable<Period?> data;

  const Day({required final this.date, required final this.data});

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
    required final this.letter,
    required final this.color,
    required final this.title,
    required final this.teacher,
    required final this.name,
  });

  @override
  toString() => "{ $title, $teacher, $name }";
}

class PeriodCell extends StatelessWidget {
  final Period? period;
  final DateTime date;

  const PeriodCell({
    final Key? key,
    required final this.period,
    required final this.date,
  }) : super(key: key);

  @override
  build(final context) {
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

  void _openDialog(final BuildContext context) => showDialog(
        context: context,
        builder: (final context) {
          final data = period!;

          return AlertDialog(
            title: Text(data.title),
            contentPadding: const EdgeInsets.only(
              left: 24,
              top: 8,
              right: 24,
              bottom: 24,
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
                  padding: const EdgeInsets.only(top: 8),
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
    final Key? key,
    required final this.scrollController,
    required final this.table,
    required final this.columns,
  }) : super(key: key);

  @override
  _TableBodyState createState() => _TableBodyState();
}

class TableCell extends StatelessWidget {
  final String value;
  final double width;
  final Alignment alignment;

  const TableCell({
    final Key? key,
    required final this.value,
    final this.width = cellSize,
    final this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  build(final context) => Container(
        width: width,
        height: cellSize,
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(value),
      );
}

class TableHead extends StatelessWidget {
  final ScrollController scrollController;
  final int columns;

  const TableHead({
    final Key? key,
    required final this.scrollController,
    required final this.columns,
  }) : super(key: key);

  @override
  build(final context) => Container(
        height: cellSize,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 1, color: Colors.grey),
          ),
        ),
        child: Row(
          children: [
            const TableCell(value: "Date", width: dateWidth),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: columns,
                itemBuilder: (final context, final index) =>
                    TableCell(value: index.toString()),
              ),
            ),
          ],
        ),
      );
}

class _AttendancePageShimmer extends StatelessWidget {
  final int rows;
  final int columns;

  const _AttendancePageShimmer({
    final Key? key,
    required final this.rows,
    required final this.columns,
  }) : super(key: key);

  @override
  build(final context) {
    final size = MediaQuery.of(context).size;

    const never = NeverScrollableScrollPhysics();

    final width = size.width ~/ cellSize;
    final height = size.height ~/ cellSize;

    return columns == 0
        ? const ListTile(title: CustomShimmer())
        : ListView.builder(
            physics: never,
            itemCount: min(rows + 1, height),
            itemBuilder: (final context, final index) => SizedBox(
              height: cellSize,
              width: size.width,
              child: Row(
                children: [
                  const SizedBox(
                    width: dateWidth,
                    child: CustomShimmer(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: never,
                      itemCount: min(columns, width),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (final context, final index) =>
                          const SizedBox(
                        width: cellSize,
                        child: Center(child: CustomShimmer(width: 16)),
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

  int _rows = 15;
  int _columns = 15;

  late Future<AttendanceData> _futureAttendance = _fetchAttendance();

  @override
  build(final context) => SmartRefresher(
        physics: const BouncingScrollPhysics(),
        controller: _refreshController,
        onRefresh: _refresh,
        child: FutureBuilder<AttendanceData>(
          future: _futureAttendance,
          builder: (final context, final snapshot) {
            if (snapshot.hasError) return ErrorCard(error: "${snapshot.error}");
            if (snapshot.connectionState == ConnectionState.waiting)
              return _AttendancePageShimmer(rows: _rows, columns: _columns);

            final data = snapshot.data!;

            final table = data.table;
            final columns = data.columns;

            _saveTable(table.length, columns);

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
                          table: table,
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

    _loadTable();
  }

  Future<AttendanceData> _fetchAttendance() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://api.jumpro.pe/attendance/student_attendance_summary/?as=html&student_id=${student.id}",
        ),
        headers: userAgentHeader,
      );

      return AttendanceData.parseData(response.body);
    } on Exception {
      throw Exception("Failed to load attendance");
    }
  }

  Future<void> _loadTable() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => _rows = prefs.getInt("rows") ?? _rows);
    setState(() => _columns = prefs.getInt("columns") ?? _columns);
  }

  void _refresh() => setState(() {
        _futureAttendance = _fetchAttendance();

        _futureAttendance
            .then((final data) => _refreshController.refreshCompleted())
            .catchError((final error) => _refreshController.refreshFailed());
      });

  Future<void> _saveTable(final int rows, final int columns) async {
    final prefs = await _prefs;

    await prefs.setInt("rows", _rows = rows);
    await prefs.setInt("columns", _columns = columns);
  }
}

class _TableBodyState extends State<TableBody> {
  final _controllers = LinkedScrollControllerGroup();
  late final ScrollController _firstColumnController = _controllers.addAndGet();
  late final ScrollController _restColumnsController = _controllers.addAndGet();

  @override
  build(final context) {
    final table = widget.table;
    final columns = widget.columns;

    final length = table.length;

    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(width: 1, color: Colors.grey),
            ),
          ),
          width: dateWidth,
          child: ListView.builder(
            controller: _firstColumnController,
            physics: const ClampingScrollPhysics(),
            itemCount: length,
            itemBuilder: (final context, final index) {
              final date = DateFormat.MMMEd().format(table[index].date);

              return TableCell(
                value: date,
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
                itemBuilder: (final context, final index) {
                  final row = table[index];

                  return Row(
                    children: row.data
                        .map(
                          (final period) =>
                              PeriodCell(period: period, date: row.date),
                        )
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
