import "dart:math" as Math;

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

class News {
  final String title;
  final String? description;
  final String? image;
  final String date;
  final String url;

  const News({
    required this.title,
    required this.description,
    required this.image,
    required this.date,
    required this.url,
  });
}

class NewsCards extends StatefulWidget {
  const NewsCards({Key? key}) : super(key: key);

  @override
  NewsCardsState createState() => NewsCardsState();
}

class NewsCardsState extends State<NewsCards> {
  final _prefs = SharedPreferences.getInstance();

  int _news = 0;

  late Future<NewsData> futureNews = _fetchNews();

  @override
  build(context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final link = textTheme.bodyText2!.copyWith(color: theme.primaryColor);

    const empty = SizedBox.shrink();

    return FutureBuilder<NewsData>(
      future: futureNews,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text("${snapshot.error}");
        if (snapshot.connectionState == ConnectionState.waiting)
          return _NewsCardShimmer(news: _news);

        final news = snapshot.data!.news;
        final length = Math.min(news.length, 3);

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
                itemBuilder: (context, index) {
                  final item = news[index];

                  final description = item.description;
                  final image = item.image;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        top: 16.0,
                        right: 16.0,
                        bottom: 8.0,
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
                                            onOpen: (link) =>
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
                                        placeholder: (context, url) =>
                                            const CustomShimmer(
                                          width: 75.0,
                                          height: 40.0,
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
    final response = await http.get(
      Uri.parse("https://www.afsenyc.org/apps/news/rss"),
    );

    if (response.statusCode == 200)
      // If the server did return a 200 OK response,
      // then parse the data.
      return NewsData.parseData(response.body);
    else
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception("Failed to load news");
  }

  void _loadNews() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => _news = (prefs.getInt("news") ?? _news));
  }

  void _saveNews(int news) async {
    final prefs = await _prefs;

    await prefs.setInt("news", _news = news);
  }
}

class NewsData {
  final List<News> news;

  const NewsData({required this.news});

  factory NewsData.parseData(String data) {
    final now = DateTime.now();

    return NewsData(
      news: RssFeed.parse(data)
          .items!
          .where((item) => now.difference(item.pubDate!).inDays <= 31)
          .map(
            (item) => News(
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

  const _NewsCardShimmer({Key? key, required this.news}) : super(key: key);

  @override
  build(context) => ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: Math.max(news, 1),
        itemBuilder: (context, index) => Card(
          child: news == 0
              ? const ListTile(title: CustomShimmer())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  CustomShimmer(
                                    width: 200.0,
                                    padding: EdgeInsets.only(bottom: 6.0),
                                  ),
                                  CustomShimmer(
                                    height: 12.0,
                                    padding: EdgeInsets.only(bottom: 4.0),
                                  ),
                                  CustomShimmer(
                                    height: 12.0,
                                    padding: EdgeInsets.only(bottom: 4.0),
                                  ),
                                  CustomShimmer(
                                    height: 12.0,
                                    padding: EdgeInsets.only(bottom: 8.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const CustomShimmer(
                            width: 75.0,
                            height: 40.0,
                            radius: 0,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3.0),
                        child: Row(
                          children: const [
                            CustomShimmer(width: 200.0),
                            Spacer(),
                            CustomShimmer(width: 100.0, height: 32.0)
                          ],
                        ),
                      )
                    ],
                  ),
                ),
        ),
      );
}
