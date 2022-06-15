import "dart:convert";
import "dart:math";

import "package:expandable/expandable.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../extensions/theming.dart";
import "../utils/api.dart" as api;
import "../utils/shimmer.dart";
import "../widgets/work.dart";

class GradesNodeTree extends StatelessWidget {
  final MasteryScore score;

  const GradesNodeTree({
    required final this.score,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    const colors = {
      "green": Colors.green,
      "orange": Colors.amber,
      "red": Colors.red,
      "blue": Colors.blue,
    };

    /// Linear bar containing the score.
    final bar = Stack(
      alignment: Alignment.center,
      children: [
        // Bar
        SizedBox(
          height: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.percent,
              color: colors[score.color.toLowerCase()],
              minHeight: 24,
            ),
          ),
        ),

        // Label
        Align(
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
      final missing = score.missing;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ExpandableNotifier(
          child: ExpandablePanel(
            header: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Top row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(score.label),
                        ),
                      ),
                      Expanded(child: bar)
                    ],
                  ),

                  // Bottom row
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Date updated
                              Text(
                                "Updated ${score.recent}",
                                style: textTheme.bodySmall,
                              ),
                              // Missing assignments
                              if (missing != 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        // constraints: const BoxConstraints(
                                        //   minWidth: 20,
                                        //   minHeight: 20,
                                        // ),
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.errorContainer,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "$missing",
                                          style: TextStyle(
                                            color: colorScheme.onErrorContainer,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Weight sum
                        Text("=${sum.toStringAsFixed(0)} weight"),
                      ],
                    ),
                  )
                ],
              ),
            ),
            collapsed: const SizedBox.shrink(),
            expanded: Container(
              // Thin grey line to the left
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: children.length,
                itemBuilder: (final context, final index) =>
                    // Recursion~
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
            if (comment != null)
              Row(
                children: [
                  const Text("Comment: ", style: bold),
                  Text(comment),
                ],
              ),
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
  GradesPageState createState() => GradesPageState();
}

class GradesPageState extends State<GradesPage> {
  final _refreshController = RefreshController();

  final _prefs = SharedPreferences.getInstance();

  int _scores = 7;

  late Stream<List<Map<String, dynamic>>> _masteryStream = _broadcastScores();

  final _upcomingKey = LabeledGlobalKey<WorkCardState>("Upcoming");
  final _missingKey = LabeledGlobalKey<WorkCardState>("Missing");

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        child: Align(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 750),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _masteryStream,
                      builder: (final context, final snapshot) {
                        if (snapshot.hasError)
                          return ListTile(
                            title: Text(
                              "Failed to load grades",
                              style: TextStyle(color: theme.errorColor),
                            ),
                          );
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return _GradesPageShimmer(scores: _scores);

                        final data = snapshot.data![0];
                        final List<dynamic> scoreData =
                            jsonDecode(data["score_data"]);

                        _saveScores(scoreData.length);

                        final scores = scoreData
                            .map(
                              (final score) => MasteryScore.fromJson(
                                score as Map<String, dynamic>,
                              ),
                            )
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

  Stream<List<Map<String, dynamic>>> _broadcastScores() =>
      _fetchScores().asBroadcastStream();

  Stream<List<Map<String, dynamic>>> _fetchScores() =>
      api.getApi("student_mastery_cache");

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => _scores = prefs.getInt("scores") ?? _scores);
  }

  void _refresh() {
    setState(() => _masteryStream = _broadcastScores());

    final upcomingState = _upcomingKey.currentState!..refresh();
    final missingState = _missingKey.currentState!..refresh();

    Future.wait([
      _masteryStream.first,
      upcomingState.workStream.first,
      missingState.workStream.first,
    ])
        .then((final data) => _refreshController.refreshCompleted())
        .catchError((final error) => _refreshController.refreshFailed());
  }

  Future<void> _saveScores(final int scores) async {
    final prefs = await _prefs;

    await prefs.setInt("scores", _scores = scores);
  }
}

/// Scores are separated by two main categories.
/// We can have "sections" that contain [children], that
/// can have more "sections", or an assignment.
/// An assignment are a piece of work that build "sections".
///
/// These "sections" are essentially folders, that can contain either
/// more folders, or a file (an assignment in this context) instead.
class MasteryScore {
  /// If it contains children.
  final bool expanded;

  /// Name of score.
  final String label;

  /// Score number in string form.
  final String scoreLabel;

  /// Color associated with score.
  final String color;

  /// Percentage of score.
  final double percent;

  /// Total weight sum.
  final double sum;

  /// Number of missing assignments, if any.
  final int? missing;

  /// Additional scores nested inside.
  final List<MasteryScore>? children;

  /// Title for assignment.
  final String? title;

  /// Comment by teacher for the assignment.
  final String? comment;

  /// Date for last updated.
  final String? recent;

  /// Weight number in string form.
  final String? weight;

  /// Due date for the assignment.
  final String? end;

  /// Last modified date for the assignment.
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

    /// "mastery_bar_percent" could be an `int` or a `double`.
    /// Why? Because JumpRope. Inconsistent >:(
    // ignore: avoid_dynamic_calls
    final double percent = json["mastery_bar_percent"].toDouble();
    final Map<String, dynamic> threshold = json["threshold_details"];
    final List<dynamic>? children = json["children"];
    final double? weight = json["assessment_weight"];
    final String? end = json["assessment_end_date"];
    final String? recent = json["most_recent_date"];

    final format = DateFormat("y-M-d");

    return MasteryScore(
      expanded: json["expanded"] ?? false,
      label: label is List ? label.first : label,
      scoreLabel: json["score_label"],
      color: json["color"],
      percent: percent / 100,
      sum: json["weight_sum"],
      missing: threshold["missing_count"],
      children: children
          ?.map(
            (final score) =>
                MasteryScore.fromJson(score as Map<String, dynamic>),
          )
          .toList(growable: false),
      title: json["assessment_title"],
      comment: json["comment"],
      recent: recent != null
          ? DateFormat.MMMMEEEEd().format(format.parse(recent))
          : null,
      weight: weight?.toStringAsFixed(1),
      end:
          end != null ? DateFormat.MMMMEEEEd().format(format.parse(end)) : null,
      modified: DateFormat.MMMMEEEEd().add_jm().format(
            DateFormat("yyyy-MM-ddTHH:mm:ss").parseUtc(
              json["time_modified"],
            ),
          ),
    );
  }

  @override
  String toString() =>
      """{ $expanded, $label, $scoreLabel, $color, $percent, $sum, $missing, $children, $title, $comment, $recent, $weight, $end, $modified }""";
}

class _GradesPageShimmer extends StatelessWidget {
  final int scores;

  const _GradesPageShimmer({
    required final this.scores,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) => ListView.builder(
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
