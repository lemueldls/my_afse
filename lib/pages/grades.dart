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

  const GradesNodeTree({Key? key, required this.score}) : super(key: key);

  @override
  build(context) {
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
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: score.percent,
              color: colors[score.color],
              minHeight: 24.0,
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
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: ExpandableNotifier(
          child: ExpandablePanel(
            header: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(flex: 2, child: Text(score.label)),
                      Expanded(child: bar)
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Updated ${score.recent}",
                            style: textTheme.bodyText2!
                                .copyWith(color: textTheme.caption!.color),
                          ),
                        ),
                        // sum != 100.0 ?
                        Text("=${sum.toStringAsFixed(0)} weight")
                        // : empty
                        ,

                        // missing != 0
                        //     ? Expanded(
                        //         child: Row(
                        //           children: [
                        //             Container(
                        //               padding: const EdgeInsets.symmetric(
                        //                 horizontal: 3.0,
                        //                 vertical: 2.0,
                        //               ),
                        //               decoration: BoxDecoration(
                        //                 color: Colors.red,
                        //                 borderRadius:
                        //                     BorderRadius.circular(4.0),
                        //               ),
                        //               child: Text(
                        //                 "$missing missing",
                        //                 style: const TextStyle(
                        //                   color: Colors.white,
                        //                   fontSize: 12.0,
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
                itemBuilder: (context, index) =>
                    GradesNodeTree(score: children[index]),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4.0),
        onTap: () => _selectScore(context, score),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
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

  void _selectScore(BuildContext context, MasteryScore score) {
    const empty = SizedBox.shrink();

    const bold = TextStyle(fontWeight: FontWeight.bold);

    final comment = score.comment;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              padding: const EdgeInsets.symmetric(vertical: 8.0),
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
  const GradesPage({Key? key}) : super(key: key);

  @override
  _GradesPageState createState() => _GradesPageState();
}

class MasteryScore {
  final bool? expanded;
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
    required this.expanded,
    required this.label,
    required this.scoreLabel,
    required this.color,
    required this.percent,
    required this.sum,
    required this.missing,
    required this.children,
    required this.title,
    required this.comment,
    required this.recent,
    required this.weight,
    required this.end,
    required this.modified,
  });

  factory MasteryScore.fromJson(Map<String, dynamic> json) {
    final label = json["label"];
    final List? children = json["children"];
    final String? end = json["assessment_end_date"];
    final String? recent = json["most_recent_date"];

    final format = DateFormat("y-M-d");

    return MasteryScore(
      expanded: json["expanded"],
      label: label is List ? label[0] : label,
      scoreLabel: json["score_label"],
      color: json["color"],
      percent: json["mastery_bar_percent"] / 100,
      sum: json["weight_sum"],
      missing: json["threshold_details"]["missing_count"],
      children: children
          ?.map((score) => MasteryScore.fromJson(score))
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

  const _GradesPageShimmer({Key? key, required this.scores}) : super(key: key);

  @override
  build(context) => ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: max(scores, 1),
        itemBuilder: (context, index) => scores == 0
            ? const ListTile(title: CustomShimmer())
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
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
                                    //   padding: EdgeInsets.only(top: 4.0)
                                    // ),
                                    CustomShimmer(
                                      padding: EdgeInsets.only(
                                        top: 4.0,
                                        bottom: 8.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(
                                child: CustomShimmer(
                                  height: 24.0,
                                  padding: EdgeInsets.only(left: 8.0),
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: const [
                              CustomShimmer(width: 160.0),
                              Spacer(),
                              CustomShimmer(width: 80.0)
                            ],
                          ),
                        ],
                      ),
                    ),
                    const CustomShimmer(
                      width: 24.0,
                      height: 24.0,
                      padding: EdgeInsets.only(left: 16.0),
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
  build(context) {
    final theme = Theme.of(context);

    return SmartRefresher(
      physics: const BouncingScrollPhysics(),
      controller: _refreshController,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        child: Align(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 750.0),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: FutureBuilder<List>(
                      future: _futureMastery,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Text("${snapshot.error}");
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return _GradesPageShimmer(scores: _scores);

                        final data = snapshot.data![0];
                        final List scoreData = jsonDecode(data["score_data"]);

                        _saveScores(scoreData.length);

                        final scores = scoreData
                            .map((score) => MasteryScore.fromJson(score))
                            .toList(growable: false);
                        return scoreData.isEmpty
                            ? const ListTile(
                                title: Text("There are no grades to show."),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: scores.length,
                                itemBuilder: (context, index) =>
                                    ExpandableTheme(
                                  data: ExpandableThemeData(
                                    inkWellBorderRadius:
                                        BorderRadius.circular(4.0),
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

  void _loadScores() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => _scores = (prefs.getInt("scores") ?? _scores));
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
            .then((data) => _refreshController.refreshCompleted())
            .catchError((error) => _refreshController.refreshFailed());
      });

  void _saveScores(int scores) async {
    final prefs = await _prefs;

    await prefs.setInt("scores", _scores = scores);
  }
}
