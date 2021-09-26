import "dart:math";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_linkify/flutter_linkify.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:webfeed/webfeed.dart";

import "../extensions/list.dart";
import "../utils/shimmer.dart";
import "../utils/url.dart";
import "../widgets/error.dart";

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

  late Future<NewsData> futureNews = _fetchNews();

  @override
  build(final context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final link = textTheme.bodyText2!.copyWith(color: theme.primaryColor);

    const empty = SizedBox.shrink();

    return FutureBuilder<NewsData>(
      future: futureNews,
      builder: (final context, final snapshot) {
        if (snapshot.hasError) return ErrorCard(error: "${snapshot.error}");
        if (snapshot.connectionState == ConnectionState.waiting)
          return _NewsCardShimmer(news: _news);

        final news = snapshot.data!.news;
        final length = min(news.length, 3);

        _saveNews(length);

        return news.isEmpty
            ? const Card(
                child: ListTile(
                  enabled: false,
                  title: Text("There are no recent news."),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: length,
                itemBuilder: (final context, final index) {
                  final item = news[index];

                  final description = item.description;
                  final image = item.image;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: textTheme.subtitle1,
                                    ),
                                    description != null
                                        ? Linkify(
                                            text: description,
                                            onOpen: (final link) =>
                                                launchURL(link.url),
                                            linkStyle: link,
                                            style: TextStyle(
                                              color: textTheme.caption!.color,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                          )
                                        : empty,
                                  ],
                                ),
                              ),
                              image != null
                                  ? Expanded(
                                      flex: 0,
                                      child: CachedNetworkImage(
                                        alignment: Alignment.topCenter,
                                        imageUrl: image,
                                        placeholder:
                                            (final context, final url) =>
                                                const CustomShimmer(
                                          width: 75,
                                          height: 40,
                                          radius: 0,
                                        ),
                                      ),
                                    )
                                  : empty
                            ],
                          ),
                          Row(
                            children: [
                              Text("Published on ${item.date}"),
                              const Spacer(),
                              TextButton(
                                child: const Text("READ MORE"),
                                onPressed: () => launchURL(item.url),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _loadNews();
  }

  void refresh() => setState(() {
        futureNews = _fetchNews();
      });

  Future<NewsData> _fetchNews() async {
    try {
      final response = await http.get(
        Uri.parse("https://www.afsenyc.org/apps/news/rss"),
      );

      return NewsData.parseData(response.body);
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

    return NewsData(
      news: RssFeed.parse(data)
          .items!
          .where((final item) => now.difference(item.pubDate!).inDays <= 31)
          .map(
            (final item) => News(
              title: item.title!,
              description: item.description,
              date: DateFormat.MMMMd().format(item.pubDate!),
              image: item.media!.contents!.tryGet(0)?.url!,
              url: item.link!,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _NewsCardShimmer extends StatelessWidget {
  final int news;

  const _NewsCardShimmer({final Key? key, required final this.news})
      : super(key: key);

  @override
  build(final context) => ListView.builder(
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
                        padding: const EdgeInsets.only(top: 3),
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
