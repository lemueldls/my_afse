import "dart:convert";
import "dart:math";

import "package:expandable/expandable.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../extensions/brightness.dart";
import "../utils/api.dart" as api;
import "../utils/shimmer.dart";
import "../widgets/work.dart";

class GradesNodeTree extends StatelessWidget {
  final MasteryScore score;

  const GradesNodeTree({final Key? key, required final this.score})
      : super(key: key);

  @override
  build(final context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    const empty = SizedBox.shrink();

    const colors = {
      "Green": Colors.green,
      "Orange": Colors.amber,
      "Red": Colors.red,
      "Blue": Colors.blue,
    };

    final bar = Stack(
      children: [
        SizedBox(
          height: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.percent,
              color: colors[score.color],
              minHeight: 24,
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            score.scoreLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    if (score.expanded == true) {
      final children = score.children!;

      final sum = score.sum;
      // final missing = score.missing;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ExpandableNotifier(
          child: ExpandablePanel(
            header: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(flex: 2, child: Text(score.label)),
                      Expanded(child: bar)
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Updated ${score.recent}",
                            style: textTheme.bodyText2!
                                .copyWith(color: textTheme.caption!.color),
                          ),
                        ),
                        // sum != 100 ?
                        Text("=${sum.toStringAsFixed(0)} weight")
                        // : empty
                        ,

                        // missing != 0
                        //     ? Expanded(
                        //         child: Row(
                        //           children: [
                        //             Container(
                        //               padding: const EdgeInsets.symmetric(
                        //                 horizontal: 3,
                        //                 vertical: 2,
                        //               ),
                        //               decoration: BoxDecoration(
                        //                 color: Colors.red,
                        //                 borderRadius:
                        //                     BorderRadius.circular(4),
                        //               ),
                        //               child: Text(
                        //                 "$missing missing",
                        //                 style: const TextStyle(
                        //                   color: Colors.white,
                        //                   fontSize: 12,
                        //                 ),
                        //               ),
                        //             )
                        //           ],
                        //         ),
                        //       )
                        //     : empty,
                      ],
                    ),
                  )
                ],
              ),
            ),
            collapsed: empty,
            expanded: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: children.length,
                itemBuilder: (final context, final index) =>
                    GradesNodeTree(score: children[index]),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _selectScore(context, score),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(score.title!),
              ),
              Row(
                children: [
                  Expanded(flex: 2, child: bar),
                  Expanded(
                    child: Text(
                      "Weight: ${score.weight}",
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectScore(final BuildContext context, final MasteryScore score) {
    const empty = SizedBox.shrink();

    const bold = TextStyle(fontWeight: FontWeight.bold);

    final comment = score.comment;

    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: Text(score.title!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            comment != null
                ? Row(
                    children: [
                      const Text("Comment: ", style: bold),
                      Text(comment)
                    ],
                  )
                : empty,
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text("Score: ", style: bold),
                      Text(score.scoreLabel),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Text("Weight: ", style: bold),
                      Text(score.weight!),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Text("End Date: ", style: bold),
                  Text(score.end!),
                ],
              ),
            ),
            const Text("Last Modified: ", style: bold),
            Text(score.modified)
          ],
        ),
      ),
    );
  }
}

class GradesPage extends StatefulWidget {
  const GradesPage({final Key? key}) : super(key: key);

  @override
  _GradesPageState createState() => _GradesPageState();
}

class MasteryScore {
  final bool expanded;
  final String label;
  final String scoreLabel;
  final String color;
  final double percent;
  final double sum;
  final int? missing;
  final List<MasteryScore>? children;
  final String? title;
  final String? comment;
  final String? recent;
  final String? weight;
  final String? end;
  final String modified;

  const MasteryScore({
    required final this.expanded,
    required final this.label,
    required final this.scoreLabel,
    required final this.color,
    required final this.percent,
    required final this.sum,
    required final this.missing,
    required final this.children,
    required final this.title,
    required final this.comment,
    required final this.recent,
    required final this.weight,
    required final this.end,
    required final this.modified,
  });

  factory MasteryScore.fromJson(final Map<String, dynamic> json) {
    final label = json["label"];
    final List? children = json["children"];
    final String? end = json["assessment_end_date"];
    final String? recent = json["most_recent_date"];

    final format = DateFormat("y-M-d");

    return MasteryScore(
      expanded: json["expanded"] ?? false,
      label: label is List ? label[0] : label,
      scoreLabel: json["score_label"],
      color: json["color"],
      percent: json["mastery_bar_percent"] / 100,
      sum: json["weight_sum"],
      missing: json["threshold_details"]["missing_count"],
      children: children
          ?.map((final score) => MasteryScore.fromJson(score))
          .toList(growable: false),
      title: json["assessment_title"],
      comment: json["comment"],
      recent: recent != null
          ? DateFormat.yMMMEd().format(format.parse(recent))
          : null,
      weight: json["assessment_weight"]?.toStringAsFixed(1),
      end:
          end != null ? DateFormat.MMMMEEEEd().format(format.parse(end)) : null,
      modified: DateFormat.yMMMMEEEEd().add_jm().format(
            DateFormat("yyyy-MM-ddTHH:mm:ss").parseUtc(
              json["time_modified"],
            ),
          ),
    );
  }

  @override
  toString() =>
      "{ $expanded, $label, $scoreLabel, $color, $percent, $sum, $missing, $children, $title, $comment, $recent, $weight, $end, $modified }";
}

class _GradesPageShimmer extends StatelessWidget {
  final int scores;

  const _GradesPageShimmer({final Key? key, required final this.scores})
      : super(key: key);

  @override
  build(final context) => ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: max(scores, 1),
        itemBuilder: (final context, final index) => scores == 0
            ? const ListTile(title: CustomShimmer())
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: const [
                                    CustomShimmer(),
                                    // CustomShimmer(
                                    //   padding: EdgeInsets.only(top: 4)
                                    // ),
                                    CustomShimmer(
                                      padding: EdgeInsets.only(
                                        top: 4,
                                        bottom: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(
                                child: CustomShimmer(
                                  height: 24,
                                  padding: EdgeInsets.only(left: 8),
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: const [
                              CustomShimmer(width: 160),
                              Spacer(),
                              CustomShimmer(width: 80)
                            ],
                          ),
                        ],
                      ),
                    ),
                    const CustomShimmer(
                      width: 24,
                      height: 24,
                      padding: EdgeInsets.only(left: 16),
                    )
                  ],
                ),
              ),
      );
}

class _GradesPageState extends State<GradesPage> {
  final _refreshController = RefreshController();

  final _prefs = SharedPreferences.getInstance();

  int _scores = 7;

  late Future<List> _futureMastery = api.get("student_mastery_cache");

  final _upcomingKey = LabeledGlobalKey<WorkCardState>("Upcoming");
  final _missingKey = LabeledGlobalKey<WorkCardState>("Missing");

  @override
  build(final context) {
    final theme = Theme.of(context);

    return SmartRefresher(
      physics: const BouncingScrollPhysics(),
      controller: _refreshController,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        child: Align(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 750),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: FutureBuilder<List>(
                      future: _futureMastery,
                      builder: (final context, final snapshot) {
                        if (snapshot.hasError) return Text("${snapshot.error}");
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return _GradesPageShimmer(scores: _scores);

                        final data = snapshot.data![0];
                        final List scoreData = jsonDecode(data["score_data"]);

                        _saveScores(scoreData.length);

                        final scores = scoreData
                            .map((final score) => MasteryScore.fromJson(score))
                            .toList(growable: false);
                        return scoreData.isEmpty
                            ? const ListTile(
                                title: Text("There are no grades to show."),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: scores.length,
                                itemBuilder: (final context, final index) =>
                                    ExpandableTheme(
                                  data: ExpandableThemeData(
                                    inkWellBorderRadius:
                                        BorderRadius.circular(4),
                                    headerAlignment:
                                        ExpandablePanelHeaderAlignment.center,
                                    iconColor: theme.brightness.text,
                                  ),
                                  child: GradesNodeTree(score: scores[index]),
                                ),
                              );
                      },
                    ),
                  ),
                ),
                const Divider(),
                WorkCard(key: _upcomingKey, type: "Upcoming"),
                WorkCard(key: _missingKey, type: "Missing"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _loadScores();
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => _scores = prefs.getInt("scores") ?? _scores);
  }

  void _refresh() => setState(() {
        _futureMastery = api.get("student_mastery_cache");

        final upcomingState = _upcomingKey.currentState!;
        final missingState = _missingKey.currentState!;

        upcomingState.refresh();
        missingState.refresh();

        Future.wait([
          _futureMastery,
          upcomingState.futureWork,
          missingState.futureWork,
        ])
            .then((final data) => _refreshController.refreshCompleted())
            .catchError((final error) => _refreshController.refreshFailed());
      });

  Future<void> _saveScores(final int scores) async {
    final prefs = await _prefs;

    await prefs.setInt("scores", _scores = scores);
  }
}
