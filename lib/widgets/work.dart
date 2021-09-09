import "dart:math";

import "package:expandable/expandable.dart";
import "package:flutter/material.dart";
import "package:flutter_linkify/flutter_linkify.dart";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../extensions/brightness.dart";
import "../utils/api.dart" as api;
import "../utils/shimmer.dart";
import "../utils/url.dart";

class WorkCard extends StatefulWidget {
  final String type;

  const WorkCard({Key? key, required this.type}) : super(key: key);

  @override
  WorkCardState createState() => WorkCardState();
}

class WorkCardState extends State<WorkCard> {
  late final key = widget.type.toLowerCase();

  final _prefs = SharedPreferences.getInstance();

  int _count = 0;

  late Future<List> futureWork = api.get("${key}_work");

  @override
  build(context) {
    final textTheme = Theme.of(context).textTheme;

    final title = textTheme.headline6;

    const empty = SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 12.0,
                left: 12.0,
                bottom: 6.0,
                right: 12.0,
              ),
              child: Text("${widget.type} Work", style: title),
            ),
            FutureBuilder<List>(
              future: futureWork,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text("${snapshot.error}");
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _WorkCardShimmer(count: _count);
                }

                final count = snapshot.data!.reversed
                    .map((count) => WorkData.fromJson(count))
                    .toList(growable: false);

                _saveWork(count.length);

                return count.isEmpty
                    ? ListTile(
                        title: Text(
                          "There is no $key work.",
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: count.length,
                        itemBuilder: (context, index) {
                          final work = count[index];

                          final hasDescription = work.description.isNotEmpty;

                          final type = Text(work.type);

                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4.0),
                              onTap: () => _selectWork(work),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            work.title,
                                            style: textTheme.subtitle1,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        hasDescription ? type : empty,
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: hasDescription
                                              ? Text(
                                                  work.description
                                                      .replaceAll("\n", " "),
                                                  style: textTheme.bodyText2
                                                      ?.copyWith(
                                                    color: textTheme
                                                        .caption!.color,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                )
                                              : type,
                                        ),
                                        Text(work.course),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _loadWork();
  }

  void refresh() => setState(() {
        futureWork = api.get("${key}_work");
      });

  void _loadWork() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => _count = (prefs.getInt(key) ?? _count));
  }

  void _saveWork(int count) async {
    final prefs = await _prefs;

    await prefs.setInt(key, _count = count);
  }

  void _selectWork(WorkData work) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    const bold = TextStyle(fontWeight: FontWeight.bold);

    final link = textTheme.bodyText2!.copyWith(color: theme.primaryColor);

    final description = work.description;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(work.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(work.type),
            ),
            description.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ExpandableNotifier(
                      child: ExpandablePanel(
                        header: Text("Description:", style: bold),
                        theme: ExpandableThemeData(
                          headerAlignment:
                              ExpandablePanelHeaderAlignment.center,
                          iconColor: theme.brightness.text,
                          useInkWell: false,
                          tapBodyToExpand: true,
                          tapBodyToCollapse: true,
                        ),
                        collapsed: Linkify(
                          text: work.description,
                          onOpen: (link) => launchURL(link.url),
                          linkStyle: link,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        expanded: Linkify(
                          text: work.description,
                          onOpen: (link) => launchURL(link.url),
                          linkStyle: link,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text("Score Code: ", style: bold),
                      Text(work.code),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Text("Weight: ", style: bold),
                      Text(work.weight),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text("End Date: ", style: bold),
                Text(work.end),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(work.teacherName)),
                      Text(work.course),
                    ],
                  ),
                  Linkify(
                    text: work.teacherEmail,
                    onOpen: (link) => launchURL(link.url),
                    linkStyle: link,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkData {
  final String title;
  final String course;
  final String description;
  final String type;
  final String weight;
  final String code;
  final String end;
  final String teacherName;
  final String teacherEmail;

  const WorkData({
    required this.title,
    required this.course,
    required this.description,
    required this.type,
    required this.weight,
    required this.code,
    required this.end,
    required this.teacherName,
    required this.teacherEmail,
  });

  factory WorkData.fromJson(Map<String, dynamic> data) => WorkData(
        title: data["title"],
        course: data["course_name"],
        description: data["description"],
        type: data["type"].split(" Assessment")[0],
        weight: data["weight"].toStringAsFixed(1),
        code: data["code"],
        end: DateFormat.MMMMEEEEd().format(
          DateFormat("y-M-d").parse(data["end_date"]),
        ),
        teacherName: data["teacher_name"],
        teacherEmail: data["teacher_email"],
      );
}

class _WorkCardShimmer extends StatelessWidget {
  final int count;

  const _WorkCardShimmer({Key? key, required this.count}) : super(key: key);

  @override
  build(context) => ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: max(count, 1),
        itemBuilder: (context, index) => count == 0
            ? const ListTile(title: CustomShimmer())
            : const ListTile(
                // isThreeLine: true,
                title: CustomShimmer(),
                subtitle: CustomShimmer(),
                trailing: CustomShimmer(width: 100.0),
              ),
      );
}
