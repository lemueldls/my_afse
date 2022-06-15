import "dart:math";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_linkify/flutter_linkify.dart";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:webfeed/webfeed.dart";

import "../extensions/list.dart";
import "../utils/api.dart" as api;
import "../utils/shimmer.dart";
import "../utils/url.dart";
import "../widgets/error.dart";

const perShow = 5;

class News {
  final String title;
  final String? description;
  final String? image;
  final String date;
  final String url;

  const News({
    required final this.title,
    required final this.description,
    required final this.image,
    required final this.date,
    required final this.url,
  });
}

class NewsCards extends StatefulWidget {
  const NewsCards({final Key? key}) : super(key: key);

  @override
  NewsCardsState createState() => NewsCardsState();
}

class NewsCardsState extends State<NewsCards> {
  final _prefs = SharedPreferences.getInstance();

  int _news = 0;
  int _show = perShow;

  late Stream<NewsData> newsStream = _broadcastNews();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final link = textTheme.bodyMedium?.copyWith(color: theme.primaryColor);

    return StreamBuilder<NewsData>(
      stream: newsStream,
      builder: (final context, final snapshot) {
        if (snapshot.hasError) return ErrorCard(error: "${snapshot.error}");
        if (snapshot.connectionState == ConnectionState.waiting)
          return _NewsCardShimmer(news: _news);

        final news = snapshot.data!.news;
        final length = news.length;

        _saveNews(min(perShow, length));

        return news.isEmpty
            ? const Card(
                child: ListTile(
                  enabled: false,
                  title: Text("There are no recent news."),
                ),
              )
            : Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _show,
                    itemBuilder: (final context, final index) {
                      final item = news[index];

                      final description = item.description;
                      final image = item.image;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Title
                                        Text(
                                          item.title,
                                          style: textTheme.titleLarge,
                                        ),

                                        // Publish date
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            "Published on ${item.date}",
                                            style: textTheme.bodyMedium,
                                          ),
                                        ),

                                        // Description
                                        if (description != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Linkify(
                                              text: description,
                                              onOpen: (final link) =>
                                                  launchURL(link.url),
                                              linkStyle: link,
                                              style: TextStyle(
                                                color:
                                                    textTheme.bodySmall?.color,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 3,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Image
                                  if (image != null)
                                    Expanded(
                                      flex: 0,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 16),
                                        child: CachedNetworkImage(
                                          fit: BoxFit.fill,
                                          imageUrl: image,
                                          maxWidthDiskCache: 96,
                                          placeholder:
                                              (final context, final url) =>
                                                  const CustomShimmer(
                                            width: 96,
                                            height: 48,
                                            radius: 0,
                                          ),
                                        ),
                                      ),
                                    )
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.only(top: 16),
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    // Foreground color
                                    onPrimary:
                                        theme.colorScheme.onSecondaryContainer,
                                    // Background color
                                    primary:
                                        theme.colorScheme.secondaryContainer,
                                  ).copyWith(
                                    elevation: ButtonStyleButton.allOrNull(0),
                                  ),
                                  child: const Text("Read more"),
                                  onPressed: () => launchURL(item.url),
                                ),
                              )
                            ],
                          ),
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
  }

  @override
  void initState() {
    super.initState();

    _loadNews();
  }

  void refresh() => setState(() => newsStream = _broadcastNews());

  Stream<NewsData> _broadcastNews() => _fetchNews().asBroadcastStream();

  Stream<NewsData> _fetchNews() async* {
    try {
      final stream = api.getCached(
        "https://www.afsenyc.org/apps/news/rss",
      );

      await for (final response in stream) {
        yield NewsData.parseData(response.body);
      }
    } on Exception {
      throw Exception("Failed to load news");
    }
  }

  Future<void> _loadNews() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => _news = prefs.getInt("news") ?? _news);
  }

  Future<void> _saveNews(final int news) async {
    final prefs = await _prefs;

    await prefs.setInt("news", _news = news);
  }
}

class NewsData {
  final List<News> news;

  const NewsData({required final this.news});

  factory NewsData.parseData(final String data) {
    final now = DateTime.now();

    final news = RssFeed.parse(data)
        .items!
        // Keep news within 31 days in the past.
        .where((final item) => now.difference(item.pubDate!).inDays <= 31)
        .toList(growable: false)
      // Sort by the most recent news.
      ..sort((final a, final b) => b.pubDate!.compareTo(a.pubDate!));

    return NewsData(
      news: news
          .map(
            (final item) => News(
              title: item.title!,
              description: item.description,
              date: DateFormat.MMMMEEEEd().format(item.pubDate!),
              image: item.media!.contents!.tryGet(0)?.url,
              url: item.link!,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _NewsCardShimmer extends StatelessWidget {
  final int news;

  const _NewsCardShimmer({
    required final this.news,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) => ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: max(news, 1),
        itemBuilder: (final context, final index) => Card(
          child: news == 0
              ? const ListTile(title: CustomShimmer())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  CustomShimmer(
                                    width: 200,
                                    padding: EdgeInsets.only(bottom: 6),
                                  ),
                                  CustomShimmer(
                                    height: 12,
                                    padding: EdgeInsets.only(bottom: 4),
                                  ),
                                  CustomShimmer(
                                    height: 12,
                                    padding: EdgeInsets.only(bottom: 4),
                                  ),
                                  CustomShimmer(
                                    height: 12,
                                    padding: EdgeInsets.only(bottom: 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const CustomShimmer(
                            width: 75,
                            height: 40,
                            radius: 0,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: const [
                            CustomShimmer(width: 200),
                            Spacer(),
                            CustomShimmer(width: 100, height: 32)
                          ],
                        ),
                      )
                    ],
                  ),
                ),
        ),
      );
}
