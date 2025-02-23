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

  factory Enrollment.fromJson(final List<Map<String, dynamic>> data) {
    final enrollment = data[0];

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
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final _refreshController = RefreshController();

  late Stream<List<Map<String, dynamic>>> _schoolStream = api.getApi("school");
  late Stream<List<Map<String, dynamic>>> _enrollmentStream =
      api.getApi("school_enrollment");
  late Stream<List<Map<String, dynamic>>> _roleStream = api.getApi("role");

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final error = theme.colorScheme.error;
    final title = textTheme.titleMedium;
    const bold = TextStyle(fontWeight: FontWeight.bold);

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full name
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "${student.firstName} ${student.lastName}",
                        style: textTheme.titleLarge,
                      ),
                    ),

                    // Email
                    Text(student.email, style: title),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // School name (just because)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: StreamBuilder<List<Map<String, dynamic>>>(
                                stream: _schoolStream,
                                builder: (final context, final snapshot) {
                                  if (snapshot.hasError)
                                    return Text(
                                      "Failed to load school",
                                      style: TextStyle(color: error),
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

                          // OSIS Number
                          Text(student.externalId),
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
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _enrollmentStream,
                          builder: (final context, final snapshot) {
                            if (snapshot.hasError)
                              return Text(
                                "Failed to load enrollment",
                                style: TextStyle(color: error),
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
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _roleStream,
                        builder: (final context, final snapshot) {
                          if (snapshot.hasError)
                            return Text(
                              "Failed to load roles",
                              style: TextStyle(color: error),
                            );

                          final adviserText =
                              Text("Adviser", style: textTheme.bodySmall);
                          final followersText = Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text("Followers", style: title),
                          );

                          final followersLength = student.followers.length;
                          final hasFollowers = followersLength != 0;

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // Placeholders

                            const teacher = Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomShimmer(width: 90),
                                CustomShimmer(width: 65),
                              ],
                            );
                            const sub = Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CustomShimmer(width: 150, height: 14),
                                  CustomShimmer(width: 65, height: 14),
                                ],
                              ),
                            );

                            final children = <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(top: 8, bottom: 1),
                                child: teacher,
                              ),
                              adviserText,
                              sub,
                            ];

                            if (hasFollowers) {
                              children.add(followersText);

                              for (var i = 0; i < followersLength; i++)
                                children.add(
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Column(children: [teacher, sub]),
                                  ),
                                );

                              children.add(
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 2),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: children,
                            );
                          }

                          final roles = snapshot.data!.map(Role.fromJson);

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

                          final link = textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Adviser

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

                                // Followers

                                if (hasFollowers) followersText,

                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: followersLength,
                                  itemBuilder: (final context, final index) {
                                    final follower = followers[index];

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                follower.name,
                                                style: title,
                                              ),
                                              const Spacer(),
                                              Text(
                                                follower.type,
                                                style: title,
                                              ),
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
                                ),
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
        _schoolStream = api.getApi("school").asBroadcastStream();
        _enrollmentStream = api.getApi("school_enrollment").asBroadcastStream();
        _roleStream = api.getApi("role").asBroadcastStream();

        Future.wait([
          fetchStudent().asBroadcastStream().first,
          _schoolStream.first,
          _enrollmentStream.first,
          _roleStream.first,
        ])
            .then((final data) => _refreshController.refreshCompleted())
            .catchError((final error) => _refreshController.refreshFailed());
      });
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

  const School({required this.name});

  factory School.fromJson(final List<Map<String, dynamic>> data) {
    final school = data[0];

    return School(name: school["name"]);
  }
}
