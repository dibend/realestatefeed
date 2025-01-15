import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate Feeds',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FeedListPage(),
    );
  }
}

class FeedListPage extends StatefulWidget {
  const FeedListPage({super.key});

  @override
  FeedListPageState createState() => FeedListPageState();
}

class FeedListPageState extends State<FeedListPage> {
  final Map<String, Map<String, String>> rssFeeds = {
    "Zillow": {
      "Market Report": "https://www.zillow.com/blog/feed/",
      "Research": "https://www.zillow.com/research/feed/"
    },
    "Realtor.com": {"Latest News": "https://www.realtor.com/news/feed/"},
    "Redfin": {"Blog": "https://www.redfin.com/blog/feed/"},
    "Curbed": {"National News": "https://www.curbed.com/rss/index.xml"},
    "HousingWire": {"Industry News": "https://www.housingwire.com/rss"},
    "Forbes": {"Real Estate": "https://www.forbes.com/real-estate/feed/"},
    "CNBC": {"Real Estate": "https://www.cnbc.com/id/10000115/device/rss"},
    "Inman": {
      "News": "https://www.inman.com/feed/",
      "Marketing": "https://www.inman.com/category/marketing/feed/",
      "Technology": "https://www.inman.com/category/technology/feed/"
    },
    "Mashvisor": {"Real Estate Blog": "https://www.mashvisor.com/blog/feed/"}
  };

  List<Map<String, dynamic>> articles = [];
  bool isLoading = true;
  String loadingMessage = "Fetching feeds...";

  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.network(
      'https://res.cloudinary.com/luxuryp/video/upload/f_mp4,vc_h264,q_auto/v1662499129/zyql7heamgynez8zzbma.mp4',
    )..initialize().then((_) {
        setState(() {
          _videoController.setLooping(true);
          _videoController.play();
        });
      });
    fetchFeeds();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> fetchFeeds() async {
    final userAgent =
        'Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Mobile/14E5239e';

    final Set<String> articleIdentifiers = {};

    try {
      for (var feedCategory in rssFeeds.values) {
        for (var feedUrl in feedCategory.values) {
          try {
            final response = await http.get(
              Uri.parse(feedUrl),
              headers: {'User-Agent': userAgent},
            );
            if (response.statusCode == 200) {
              final rssFeed = RssFeed.parse(response.body);

              List<Map<String, dynamic>> newArticles = [];
              for (var item in rssFeed.items!) {
                final identifier =
                    '${item.title?.toLowerCase().trim()}_${item.pubDate ?? ''}';

                if (!articleIdentifiers.contains(identifier)) {
                  articleIdentifiers.add(identifier);

                  newArticles.add({
                    'title': item.title ?? 'No title',
                    'link': item.link ?? '',
                    'pubDate': item.pubDate?.toString() ?? '',
                  });
                }
              }

              setState(() {
                articles.addAll(newArticles);
                articles.sort((a, b) => b['pubDate'].compareTo(a['pubDate']));
              });
            }
          } catch (e) {
            debugPrint("Error fetching/parsing feed: $feedUrl. Error: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching feeds: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Estate Feeds'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 8,
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(loadingMessage),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchFeeds,
                    child: ListView.builder(
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        final article = articles[index];
                        return ListTile(
                          title: Text(article['title']!),
                          subtitle: Text(article['pubDate']),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WebViewScreen(url: article['link']!),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
          // Michele's Section
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WebViewScreen(
                    url: 'https://micheledibenedetto.net',
                  ),
                ),
              );
            },
            child: Container(
              height: MediaQuery.of(context).size.height * 0.2,
              color: Colors.blueGrey[900],
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController.value.size.width,
                        height: _videoController.value.size.height,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: const NetworkImage(
                            'https://res.cloudinary.com/luxuryp/images/w_1920,c_limit,f_auto,q_auto/sfxhvzwm6pt4wxokotkj/michele-dibenedetto',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Michele DiBenedetto',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Real Estate Broker',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
