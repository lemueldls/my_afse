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
    required this.start,
    required this.end,
  });

  factory Enrollment.fromJson(List data) {
    final enrollment = data[0];

    format(String date) =>
        DateFormat.yMMMEd().format(DateFormat("y-M-d").parse(date));

    final end = enrollment["end_date"];

    return Enrollment(
      start: format(enrollment["start_date"]),
      end: end == null ? null : format(end),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

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
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.schedule,
  });

  factory Role.fromJson(Map<String, dynamic> role) {
    return Role(
      id: role["id"],
      name: role["nickname"],
      email: role["email"],
      type: role["type"],
      schedule: role["schedule_name"],
    );
  }
}

class School {
  final String name;

  const School({required this.name});

  factory School.fromJson(List data) {
    final school = data[0];

    return School(name: school["name"]);
  }
}

class _ProfilePageState extends State<ProfilePage> {
  final _refreshController = RefreshController();

  late Future<List> _futureSchool = api.get("school");
  late Future<List> _futureEnrollment = api.get("school_enrollment");
  late Future<List> _futureRole = api.get("role");

  @override
  build(context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final title = textTheme.subtitle1;
    const bold = TextStyle(fontWeight: FontWeight.bold);

    const empty = SizedBox.shrink();

    final _followers = student.followers.length;

    return SmartRefresher(
      physics: const BouncingScrollPhysics(),
      controller: _refreshController,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500.0),
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        "${student.firstName} ${student.lastName}",
                        style: textTheme.headline6,
                      ),
                    ),
                    Text(student.email, style: title),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: FutureBuilder<List>(
                                future: _futureSchool,
                                builder: (context, snapshot) {
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
                        FutureBuilder<List>(
                          future: _futureEnrollment,
                          builder: (context, snapshot) {
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
                      padding: const EdgeInsets.only(top: 4.0),
                      child: FutureBuilder<List>(
                        future: _futureRole,
                        builder: (context, snapshot) {
                          final subtitle = textTheme.bodyText2!.copyWith(
                            color: textTheme.caption!.color,
                          );

                          final adviserText = Text("Adviser", style: subtitle);
                          final followersText = Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text("Followers", style: title),
                          );

                          final hasFollowers = _followers != 0;

                          final teacher = Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              CustomShimmer(width: 90.0),
                              CustomShimmer(width: 65.0),
                            ],
                          );
                          final sub = Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                CustomShimmer(width: 150.0, height: 14.0),
                                CustomShimmer(width: 65.0, height: 14.0),
                              ],
                            ),
                          );

                          final List<Widget> children = [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 1.0),
                              child: teacher,
                            ),
                            adviserText,
                            sub
                          ];

                          if (hasFollowers) {
                            children.add(followersText);

                            for (int i = 0; i < _followers; i++)
                              children.add(Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(children: [teacher, sub]),
                              ));

                            children.add(
                              const Padding(
                                padding: EdgeInsets.only(bottom: 2.0),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children,
                            );

                          final roles =
                              snapshot.data!.map((role) => Role.fromJson(role));

                          final adviser = roles.firstWhere(
                            (role) => role.id == student.adviser,
                          );
                          final followers = student.followers
                              .map(
                                (follower) => roles
                                    .firstWhere((role) => role.id == follower),
                              )
                              .toList(growable: false);

                          final link =
                              subtitle.copyWith(color: theme.primaryColor);

                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
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
                                      onOpen: (link) => launchURL(link.url),
                                      linkStyle: link,
                                    ),
                                    const Spacer(),
                                    Text(adviser.schedule),
                                  ],
                                ),
                                hasFollowers ? followersText : empty,
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: followers.length,
                                  itemBuilder: (context, index) {
                                    final follower = followers[index];

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
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
                                                onOpen: (link) =>
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

        Future.wait([
          fetchStudent(),
          _futureSchool,
          _futureEnrollment,
          _futureRole,
        ])
            .then((data) => _refreshController.refreshCompleted())
            .catchError((error) => _refreshController.refreshFailed());
      });
}
