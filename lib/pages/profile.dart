import "package:flutter/material.dart";
import "package:flutter_linkify/flutter_linkify.dart";
import "package:intl/intl.dart";
import "package:pull_to_refresh/pull_to_refresh.dart";

import "../utils/api.dart" as api;
import "../utils/shimmer.dart";
import "../utils/student.dart";
import "../utils/url.dart";

class Enrollment {
  final String start;
  final String? end;

  const Enrollment({
    required final this.start,
    required final this.end,
  });

  factory Enrollment.fromJson(final List<dynamic> data) {
    final Map<String, dynamic> enrollment = data[0];

    String format(final String date) =>
        DateFormat.yMMMEd().format(DateFormat("y-M-d").parse(date));

    final end = enrollment["end_date"];

    return Enrollment(
      start: format(enrollment["start_date"]),
      end: end == null ? null : format(end),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({final Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class Role {
  final int id;
  final String name;
  final String email;
  final String type;
  final String schedule;

  const Role({
    required final this.id,
    required final this.name,
    required final this.email,
    required final this.type,
    required final this.schedule,
  });

  factory Role.fromJson(final Map<String, dynamic> role) => Role(
        id: role["id"],
        name: role["nickname"],
        email: role["email"],
        type: role["type"],
        schedule: role["schedule_name"],
      );
}

class School {
  final String name;

  const School({required final this.name});

  factory School.fromJson(final List<dynamic> data) {
    final Map<String, dynamic> school = data[0];

    return School(name: school["name"]);
  }
}

class _ProfilePageState extends State<ProfilePage> {
  final _refreshController = RefreshController();

  late Future<List<dynamic>> _futureSchool = api.get("school");
  late Future<List<dynamic>> _futureEnrollment = api.get("school_enrollment");
  late Future<List<dynamic>> _futureRole = api.get("role");

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final title = textTheme.subtitle1;
    const bold = TextStyle(fontWeight: FontWeight.bold);

    final _followers = student.followers.length;

    return SmartRefresher(
      physics: const BouncingScrollPhysics(),
      controller: _refreshController,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "${student.firstName} ${student.lastName}",
                        style: textTheme.headline6,
                      ),
                    ),
                    Text(student.email, style: title),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: FutureBuilder<List<dynamic>>(
                                future: _futureSchool,
                                builder: (final context, final snapshot) {
                                  if (snapshot.hasError)
                                    return const Text(
                                      "Failed to load school",
                                      style: TextStyle(color: Colors.red),
                                    );
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting)
                                    return const CustomShimmer();

                                  final school =
                                      School.fromJson(snapshot.data!);

                                  return Text(school.name, style: bold);
                                },
                              ),
                            ),
                          ),
                          Text(student.externalId)
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Text("Last Modified: ", style: bold),
                        Text(student.modified),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Enrollment: ", style: bold),
                        FutureBuilder<List<dynamic>>(
                          future: _futureEnrollment,
                          builder: (final context, final snapshot) {
                            if (snapshot.hasError)
                              return const Text(
                                "Failed to load enrollment",
                                style: TextStyle(color: Colors.red),
                              );
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              return const Expanded(child: CustomShimmer());

                            final enrollment =
                                Enrollment.fromJson(snapshot.data!);
                            final end = enrollment.end;

                            return Text(
                              enrollment.start + (end == null ? "" : "—$end"),
                            );
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: FutureBuilder<List<dynamic>>(
                        future: _futureRole,
                        builder: (final context, final snapshot) {
                          if (snapshot.hasError)
                            return const Text(
                              "Failed to load roles",
                              style: TextStyle(color: Colors.red),
                            );

                          final subtitle = textTheme.bodyText2!.copyWith(
                            color: textTheme.caption!.color,
                          );

                          final adviserText = Text("Adviser", style: subtitle);
                          final followersText = Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text("Followers", style: title),
                          );

                          final hasFollowers = _followers != 0;

                          final teacher = Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              CustomShimmer(width: 90),
                              CustomShimmer(width: 65),
                            ],
                          );
                          final sub = Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                CustomShimmer(width: 150, height: 14),
                                CustomShimmer(width: 65, height: 14),
                              ],
                            ),
                          );

                          final children = <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 1),
                              child: teacher,
                            ),
                            adviserText,
                            sub
                          ];

                          if (hasFollowers) {
                            children.add(followersText);

                            for (var i = 0; i < _followers; i++)
                              children.add(
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(children: [teacher, sub]),
                                ),
                              );

                            children.add(
                              const Padding(
                                padding: EdgeInsets.only(bottom: 2),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children,
                            );

                          final roles = snapshot.data!
                              .map((final role) => Role.fromJson(role));

                          final adviser = roles.firstWhere(
                            (final role) => role.id == student.adviser,
                          );
                          final followers = student.followers
                              .map(
                                (final follower) => roles.firstWhere(
                                  (final role) => role.id == follower,
                                ),
                              )
                              .toList(growable: false);

                          final link =
                              subtitle.copyWith(color: theme.primaryColor);

                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(adviser.name, style: title),
                                    const Spacer(),
                                    Text(adviser.type, style: title),
                                  ],
                                ),
                                adviserText,
                                Row(
                                  children: [
                                    Linkify(
                                      text: adviser.email,
                                      onOpen: (final link) =>
                                          launchURL(link.url),
                                      linkStyle: link,
                                    ),
                                    const Spacer(),
                                    Text(adviser.schedule),
                                  ],
                                ),
                                if (hasFollowers) followersText,
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: followers.length,
                                  itemBuilder: (final context, final index) {
                                    final follower = followers[index];

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(follower.name, style: title),
                                              const Spacer(),
                                              Text(follower.type, style: title),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Linkify(
                                                text: follower.email,
                                                onOpen: (final link) =>
                                                    launchURL(link.url),
                                                linkStyle: link,
                                              ),
                                              const Spacer(),
                                              Text(follower.schedule),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _refresh() => setState(() {
        _futureSchool = api.get("school");
        _futureEnrollment = api.get("school_enrollment");
        _futureRole = api.get("role");

        // Still waiting 🥲
        Future.wait([
          fetchStudent(),
          _futureSchool,
          _futureEnrollment,
          _futureRole,
        ])
            .then((final data) => _refreshController.refreshCompleted())
            .catchError((final error) => _refreshController.refreshFailed());
      });
}
