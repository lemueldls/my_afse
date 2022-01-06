import "dart:math";

import "package:expandable/expandable.dart";
import "package:flutter/material.dart";
import "package:flutter_linkify/flutter_linkify.dart";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../extensions/theming.dart";
import "../utils/api.dart" as api;
import "../utils/shimmer.dart";
import "../utils/url.dart";

/// Used to create cards containing information about certain work from the API.
/// This is made for upcoming and missing work as they have the same format.
class WorkCard extends StatefulWidget {
  final String type;

  const WorkCard({
    required final this.type,
    final Key? key,
  }) : super(key: key);

  @override
  WorkCardState createState() => WorkCardState();
}

class WorkCardState extends State<WorkCard> {
  late final key = widget.type.toLowerCase();

  final _prefs = SharedPreferences.getInstance();

  int _count = 0;

  late Future<List<dynamic>> futureWork = api.get("${key}_work");

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final title = textTheme.headline6;

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
            FutureBuilder<List<dynamic>>(
              future: futureWork,
              builder: (final context, final snapshot) {
                if (snapshot.hasError)
                  return ListTile(
                    title: Text(
                      "Failed to load $key work",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
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

                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => _selectWork(work),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    // Title
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
                                        Text(work.type),
                                      ],
                                    ),

                                    // Description
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            work.description
                                                .replaceAll("\n", " "),
                                            style:
                                                textTheme.bodyText2?.copyWith(
                                              color: textTheme.caption!.color,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
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

    final link = textTheme.bodyText2!.copyWith(color: theme.primaryContrast);

    final description = work.description;
    final code = work.code;

    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: Text(work.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Work type
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(work.type),
            ),

            // Description
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ExpandableNotifier(
                  child: ExpandablePanel(
                    header: const Text("Description:", style: bold),
                    theme: ExpandableThemeData(
                      headerAlignment: ExpandablePanelHeaderAlignment.center,
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
              ),

            Row(
              children: [
                if (code != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Text("Score Code: ", style: bold),
                        Text(code),
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
                  const Text("Teacher:", style: bold),
                  Row(
                    children: [
                      Expanded(child: Text(work.teacherName)),
                      Expanded(child: Text(work.course)),
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
  final String? code;
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

  factory WorkData.fromJson(final Map<String, dynamic> data) {
    final String type = data["type"];
    final double weight = data["weight"];

    return WorkData(
      title: data["title"],
      course: data["course_name"],
      description: data["description"],
      type: type.split(" Assessment")[0],
      weight: weight.toStringAsFixed(1),
      code: data["code"],
      end: DateFormat.MMMMEEEEd().format(
        DateFormat("y-M-d").parse(data["end_date"]),
      ),
      teacherName: data["teacher_name"],
      teacherEmail: data["teacher_email"],
    );
  }
}

class _WorkCardShimmer extends StatelessWidget {
  final int count;

  const _WorkCardShimmer({
    required final this.count,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) => ListView.builder(
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
