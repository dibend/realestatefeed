import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RealEstateFeed',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF4F1EE),
        primaryColor: const Color(0xFF5A2A27),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5A2A27),
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF5A2A27),
          secondary: const Color(0xFFF4F1EE),
        ),
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

  List<Map<String, dynamic>> allArticles = [];
  List<Map<String, dynamic>> filteredArticles = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

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
    searchController.dispose();
    super.dispose();
  }

  String formatPubDateUTC(DateTime utcDateTime) {
    final df = DateFormat("EEE, MMM d, yyyy - HH:mm 'UTC'");
    return df.format(utcDateTime.toUtc());
  }

  Future<void> fetchFeeds() async {
    const userAgent =
        'Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Mobile/14E5239e';
    final Set<String> identifiers = {};
    final List<Map<String, dynamic>> fetchedArticles = [];
    final DateTime now = DateTime.now().toUtc();

    for (var source in rssFeeds.entries) {
      for (var feedUrl in source.value.values) {
        try {
          final response = await http
              .get(Uri.parse(feedUrl), headers: {'User-Agent': userAgent});
          if (response.statusCode == 200) {
            final rssFeed = RssFeed.parse(response.body);
            for (var item in rssFeed.items ?? []) {
              final id =
                  '${item.title?.toLowerCase().trim()}_${item.pubDate ?? item.link ?? ''}';
              if (!identifiers.contains(id)) {
                identifiers.add(id);
                final pubDate = item.pubDate?.toUtc().isAfter(now) ?? false
                    ? now
                    : item.pubDate?.toUtc() ?? now;
                fetchedArticles.add({
                  'title': item.title ?? 'No title',
                  'link': item.link ?? '',
                  'rawDate': pubDate,
                  'pubDate': formatPubDateUTC(pubDate),
                  'source': source.key
                });
              }
            }
          }
        } catch (e) {
          debugPrint('Error loading feed $feedUrl: $e');
        }
      }
    }

    fetchedArticles.sort((a, b) => b['rawDate'].compareTo(a['rawDate']));
    if (mounted) {
      setState(() {
        allArticles = fetchedArticles;
        filteredArticles = fetchedArticles;
        isLoading = false;
      });
    }
  }

  void filterSearchResults(String query) {
    setState(() {
      filteredArticles = allArticles.where((a) {
        return a['title'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RealEstateFeed'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 200,
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: filterSearchResults,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 8,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchFeeds,
                    child: ListView.builder(
                      itemCount: filteredArticles.length,
                      itemBuilder: (context, index) {
                        final article = filteredArticles[index];
                        final isEven = index % 2 == 0;
                        final bgColor = isEven
                            ? const Color(0xFF5A2A27)
                            : const Color(0xFFF4F1EE);
                        final textColor =
                            isEven ? Colors.white : Colors.black87;

                        return Container(
                          color: bgColor,
                          child: ListTile(
                            title: Text(
                              article['title'],
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${article['pubDate']} • ${article['source']}",
                              style:
                                  TextStyle(color: textColor.withOpacity(0.8)),
                            ),
                            onTap: () {
                              final link = article['link'];
                              if (link.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WebViewScreen(url: link),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
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
              color: const Color(0xFF5A2A27),
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
                        const CircleAvatar(
                          radius: 35,
                          backgroundImage: NetworkImage(
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
                                shadows: [
                                  Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black),
                                ],
                              ),
                            ),
                            Text(
                              'Real Estate Broker',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                shadows: [
                                  Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black),
                                ],
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
  State<WebViewScreen> createState() => _WebViewScreenState();
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
      appBar: AppBar(title: const Text('Article')),
      body: WebViewWidget(controller: controller),
    );
  }
}
