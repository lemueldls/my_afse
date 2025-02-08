import "dart:math";

import "package:flutter/material.dart";
import "package:icalendar_parser/icalendar_parser.dart";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../utils/api.dart" as api;
import "../utils/shimmer.dart";
import "../utils/url.dart";
import "../widgets/error.dart";

/// Convert to `HOUR_MINUTE` format.
String jm(final IcsDateTime time) => DateFormat.jm().format(time.toDateTime()!);

const perShow = 5;

class Event {
  final String summary;
  final String time;
  final String? location;
  final String url;

  const Event({
    required this.summary,
    required this.time,
    required this.location,
    required this.url,
  });
}

class EventCards extends StatefulWidget {
  const EventCards({final Key? key}) : super(key: key);

  @override
  EventCardsState createState() => EventCardsState();
}

class EventCardsState extends State<EventCards> {
  final _prefs = SharedPreferences.getInstance();

  int _events = 0;
  int _show = perShow;

  late Stream<EventData> eventsStream = _broadcastEvents();

  @override
  Widget build(final BuildContext context) => StreamBuilder<EventData>(
        stream: eventsStream,
        builder: (final context, final snapshot) {
          if (snapshot.hasError) return ErrorCard(error: "${snapshot.error}");
          if (snapshot.connectionState == ConnectionState.waiting)
            return _EventsCardShimmer(events: _events);

          final events = snapshot.data!.events;
          final length = events.length;

          _saveEvents(min(perShow, length));

          return events.isEmpty
              ? const ListTile(
                  enabled: false,
                  title: Text("There are no upcoming events."),
                )
              : Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (final context, final i) =>
                          const Divider(
                        height: 0,
                      ),
                      physics: const ClampingScrollPhysics(),
                      itemCount: _show,
                      itemBuilder: (final context, final index) {
                        final event = events[index];

                        final location = event.location;
                        final hasLocation = location != null;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          isThreeLine: hasLocation,
                          title: Text(event.summary),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Time
                              Text(event.time),

                              // Location, if any
                              if (hasLocation)
                                Row(
                                  children: [
                                    const Text(
                                      "Location: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(location),
                                  ],
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => launchURL(event.url),
                          ),
                        );
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _show == perShow
                              ? null
                              : () => setState(
                                    () => _show = max(
                                      _show - perShow,
                                      perShow,
                                    ),
                                  ),
                          child: const Text("Show less"),
                        ),
                        TextButton(
                          onPressed: _show == length
                              ? null
                              : () => setState(
                                    () => _show = min(
                                      _show + perShow,
                                      length,
                                    ),
                                  ),
                          child: const Text("Show more"),
                        ),
                      ],
                    ),
                  ],
                );
        },
      );

  @override
  void initState() {
    super.initState();

    _loadEvents();
  }

  void refresh() => setState(() => eventsStream = _broadcastEvents());

  Stream<EventData> _broadcastEvents() => _fetchEvents().asBroadcastStream();

  Stream<EventData> _fetchEvents() async* {
    try {
      final stream = api.getCached("https://www.afsenyc.org/apps/events/ical");

      await for (final response in stream)
        yield EventData.parseData(response.body);
    } on Exception {
      throw Exception("Failed to load events");
    }
  }

  Future<void> _loadEvents() async {
    final prefs = await _prefs;

    setState(() => _events = prefs.getInt("events") ?? _events);
  }

  Future<void> _saveEvents(final int events) async {
    final prefs = await _prefs;

    await prefs.setInt("events", _events = events);
  }
}

class EventData {
  final List<Event> events;

  const EventData({required this.events});

  factory EventData.parseData(final String data) {
    final ical = ICalendar.fromString(data);
    final now = DateTime.now();

    final events = ical.data.where(
      (final event) {
        final String type = event["type"];

        // Filter in only events from the calendar.
        if (type != "VEVENT") return false;

        final IcsDateTime start = event["dtstart"];

        // Keep events within 31 days in the future.
        return now.difference(start.toDateTime()!).inDays <= 31;
      },
    ).toList(growable: false)
      ..sort(
        // Sort by upcoming events.
        (final a, final b) {
          final IcsDateTime startA = a["dtstart"];
          final IcsDateTime startB = b["dtstart"];

          return startA.toDateTime()!.compareTo(startB.toDateTime()!);
        },
      );

    return EventData(
      events: events.map(
        (final event) {
          final String summary = event["summary"];

          final IcsDateTime start = event["dtstart"];
          final IcsDateTime? end = event["dtend"];

          final formattedStart =
              DateFormat.MMMMEEEEd().format(start.toDateTime()!);
          final formattedEnd = end != null ? " to ${jm(end)}" : "";

          return Event(
            summary: summary.split(" (Events)")[0],
            time: "$formattedStart, ${jm(start)}$formattedEnd",
            location: event["location"],
            url: event["url"],
          );
        },
      ).toList(growable: false),
    );
  }
}

class _EventsCardShimmer extends StatelessWidget {
  final int events;

  const _EventsCardShimmer({
    required this.events,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) => ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: max(events, 1),
        itemBuilder: (final context, final index) => Card(
          child: events == 0
              ? const ListTile(title: CustomShimmer())
              : const ListTile(
                  title: CustomShimmer(),
                  subtitle: CustomShimmer(),
                  trailing: CustomShimmer(
                    width: 24,
                    height: 24,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
        ),
      );
}
