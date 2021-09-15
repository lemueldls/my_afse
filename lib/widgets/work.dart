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

  const WorkCard({final Key? key, required final this.type}) : super(key: key);

  @override
  WorkCardState createState() => WorkCardState();
}

class WorkCardState extends State<WorkCard> {
  late final key = widget.type.toLowerCase();

  final _prefs = SharedPreferences.getInstance();

  int _count = 0;

  late Future<List> futureWork = api.get("${key}_work");

  @override
  build(final context) {
    final textTheme = Theme.of(context).textTheme;

    final title = textTheme.headline6;

    const empty = SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 12,
                left: 12,
                bottom: 6,
                right: 12,
              ),
              child: Text("${widget.type} Work", style: title),
            ),
            FutureBuilder<List>(
              future: futureWork,
              builder: (final context, final snapshot) {
                if (snapshot.hasError) return Text("${snapshot.error}");
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _WorkCardShimmer(count: _count);
                }

                final count = snapshot.data!.reversed
                    .map((final count) => WorkData.fromJson(count))
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
                        itemBuilder: (final context, final index) {
                          final work = count[index];

                          final hasDescription = work.description.isNotEmpty;

                          final type = Text(work.type);

                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => _selectWork(work),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
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

  Future<void> _loadWork() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => _count = prefs.getInt(key) ?? _count);
  }

  Future<void> _saveWork(final int count) async {
    final prefs = await _prefs;

    await prefs.setInt(key, _count = count);
  }

  void _selectWork(final WorkData work) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    const bold = TextStyle(fontWeight: FontWeight.bold);

    final link = textTheme.bodyText2!.copyWith(color: theme.primaryColor);

    final description = work.description;

    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: Text(work.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(work.type),
            ),
            description.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ExpandableNotifier(
                      child: ExpandablePanel(
                        header: const Text("Description:", style: bold),
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
                          onOpen: (final link) => launchURL(link.url),
                          linkStyle: link,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        expanded: Linkify(
                          text: work.description,
                          onOpen: (final link) => launchURL(link.url),
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
              padding: const EdgeInsets.only(top: 8),
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
                    onOpen: (final link) => launchURL(link.url),
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
    required final this.title,
    required final this.course,
    required final this.description,
    required final this.type,
    required final this.weight,
    required final this.code,
    required final this.end,
    required final this.teacherName,
    required final this.teacherEmail,
  });

  factory WorkData.fromJson(final Map<String, dynamic> data) => WorkData(
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

  const _WorkCardShimmer({final Key? key, required final this.count})
      : super(key: key);

  @override
  build(final context) => ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: max(count, 1),
        itemBuilder: (final context, final index) => count == 0
            ? const ListTile(title: CustomShimmer())
            : const ListTile(
                // isThreeLine: true,
                title: CustomShimmer(),
                subtitle: CustomShimmer(),
                trailing: CustomShimmer(width: 100),
              ),
      );
}
