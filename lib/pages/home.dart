import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../extensions/list.dart";
import "../utils/shimmer.dart";
import "../utils/student.dart";
import "../widgets/events.dart";
import "../widgets/news.dart";

class HomePage extends StatefulWidget {
  const HomePage({final Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _refreshController = RefreshController();

  final _prefs = SharedPreferences.getInstance();

  final _eventsKey = LabeledGlobalKey<EventCardsState>("Events");
  final _newsKey = LabeledGlobalKey<NewsCardsState>("News");

  Timer? _timer;
  String? _greeting;

  @override
  build(final context) {
    final textTheme = Theme.of(context).textTheme;

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
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: _greeting != null
                            ? Text(
                                "$_greeting, ${student.firstName}",
                                style: textTheme.headline4,
                                textAlign: TextAlign.center,
                              )
                            : const CustomShimmer(padding: EdgeInsets.all(16)),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text("Events", style: textTheme.headline6),
                ),
                EventCards(key: _eventsKey),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text("News", style: textTheme.headline6),
                ),
                NewsCards(key: _newsKey),
              ],
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

    _updateGreeting();
  }

  void _refresh() {
    final eventsState = _eventsKey.currentState!;
    final newsState = _newsKey.currentState!;

    eventsState.refresh();
    newsState.refresh();

    Future.wait([eventsState.futureEvents, newsState.futureNews])
        .then((final data) => _refreshController.refreshCompleted())
        .catchError((final error) => _refreshController.refreshFailed());
  }

  Future<void> _updateGreeting() async {
    final now = DateTime.now();

    final prefs = await _prefs;

    List<String> crisis = prefs.getStringList("crisis") ?? const [""];
    final day = now.day;

    const crises = [
      "What if your life is a lie",
      "Does the universe exist",
      "Where do we go when we die",
      "Is one lifetime enough",
      "Are we alone in the universe",
      "Do animals have souls",
      "Do you believe in fate",
      "Do soulmates exist",
      "Are there limits to creativity",
      "Why do you think we're here",
      "What makes you special",
      "Can art be defined",
    ];

    if (int.tryParse(crisis.first) != day) {
      await prefs.setStringList(
        "crisis",
        crisis = [day.toString(), Random().nextInt(crises.length).toString()],
      );
    }

    final index = int.parse(crisis[1]);
    final thoughts = crises[index];

    final messages = {
      1: "Go to SLEEP",
      5: thoughts,
      11: "Good Morning",
      12: "G'Day",
      16: "Good Afternoon",
      21: "Good Evening",
      22: "Sweet Dreams"
    };

    final hour = now.hour;

    final keys = messages.keys;
    final message =
        keys.where((final time) => time >= hour).toList(growable: false);

    final next = DateTime(now.year, now.month, now.day, message.tryGet(1) ?? 24)
        .difference(now);

    _timer = Timer(next, _updateGreeting);

    final greeting = messages[message.tryGet(0) ?? keys.last]!;
    if (_greeting != greeting) setState(() => _greeting = greeting);
  }
}
