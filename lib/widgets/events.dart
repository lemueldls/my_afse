import "dart:math";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:icalendar_parser/icalendar_parser.dart";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../utils/shimmer.dart";
import "../utils/url.dart";

class Event {
  final String summary;
  final String time;
  final String? location;
  final String url;

  const Event({
    required final this.summary,
    required final this.time,
    required final this.location,
    required final this.url,
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

  late Future<EventData> futureEvents = _fetchEvents();

  @override
  build(final context) => FutureBuilder<EventData>(
        future: futureEvents,
        builder: (final context, final snapshot) {
          if (snapshot.hasError) return Text("${snapshot.error}");
          if (snapshot.connectionState == ConnectionState.waiting)
            return _EventsCardShimmer(events: _events);

          final events = snapshot.data!.events;
          final length = min(events.length, 5);

          _saveEvents(length);

          return events.isEmpty
              ? const Card(
                  child: ListTile(
                    enabled: false,
                    title: Text("There are no upcoming events."),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: length,
                  itemBuilder: (final context, final index) {
                    final event = events[index];

                    final location = event.location;
                    final hasLocation = location != null;

                    return Card(
                      child: ListTile(
                        isThreeLine: hasLocation,
                        title: Text(event.summary),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.time),
                            hasLocation
                                ? Row(
                                    children: [
                                      const Text(
                                        "Location: ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(location!)
                                    ],
                                  )
                                : const SizedBox.shrink()
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => launchURL(event.url),
                        ),
                      ),
                    );
                  },
                );
        },
      );

  @override
  void initState() {
    super.initState();

    _loadEvents();
  }

  void refresh() => setState(() {
        futureEvents = _fetchEvents();
      });

  Future<EventData> _fetchEvents() async {
    final response = await http.get(
      Uri.parse("https://www.afsenyc.org/apps/events/ical"),
    );

    if (response.statusCode == 200)
      // If the server did return a 200 OK response,
      // then parse the data.
      return EventData.parseData(response.body);
    else
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception("Failed to load events");
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

  const EventData({required final this.events});

  factory EventData.parseData(final String data) {
    final ical = ICalendar.fromString(data);
    final now = DateTime.now();

    return EventData(
      events: ical.data
          .where(
        (final event) =>
            event["type"] == "VEVENT" &&
            now.difference(event["dtstart"].toDateTime()).inDays <= 31,
      )
          .map(
        (final event) {
          jm(final IcsDateTime time) =>
              DateFormat.jm().format(time.toDateTime()!);

          final IcsDateTime start = event["dtstart"];
          final IcsDateTime? end = event["dtend"];

          return Event(
            summary: event["summary"].split(" (Events)")[0],
            time:
                "${DateFormat.MMMMd().format(start.toDateTime()!)}, ${jm(start)}" +
                    (end != null ? " to ${jm(end)}" : ""),
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

  const _EventsCardShimmer({final Key? key, required final this.events})
      : super(key: key);

  @override
  build(final context) => ListView.builder(
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
