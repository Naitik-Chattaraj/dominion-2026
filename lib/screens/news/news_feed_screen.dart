import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/news_service.dart';
import '../../widgets/liquid_glass_container.dart';
import '../../utils/app_haptics.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  late Future<List<NewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  void _loadNews({bool forceRefresh = false}) {
    setState(() {
      _newsFuture = NewsService.instance.fetchLocalNews(forceRefresh: forceRefresh);
    });
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    try {
      final Uri url = Uri.parse(urlString);
      final didLaunch = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open article in browser.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open article link.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatTimeAgo(String pubDate) {
    try {
      final date = DateTime.parse(pubDate);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }

  Color _getCategoryColor(SafetyCategory category) {
    switch (category) {
      case SafetyCategory.crime: return Colors.redAccent;
      case SafetyCategory.hazard: return Colors.orangeAccent;
      case SafetyCategory.traffic: return Colors.amber;
      case SafetyCategory.generalAlert: return Colors.lightBlueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: Stack(
        children: [
          // Background subtle ambient light
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A7C4DFF), // subtle purple glow
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 10.0),
                  child: Text(
                    'Local Intelligence',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 20.0),
                  child: Text(
                    'Latest verified updates from around your area',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF908A99),
                    ),
                  ),
                ),
                
                Expanded(
                  child: FutureBuilder<List<NewsArticle>>(
                    future: _newsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
                        );
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wifi_off_rounded,
                                  color: Color(0xFF908A99),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Unable to load latest intelligence.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF908A99),
                                    fontSize: 15,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                LiquidGlassContainer(
                                  onTap: () {
                                    AppHaptics.cardTap();
                                    _loadNews(forceRefresh: true);
                                  },
                                  borderRadius: 14,
                                  tintColor: const Color(0xFF2C1638),
                                  tintOpacity: 0.85,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  child: const Text(
                                    'Retry Fetching',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final articles = snapshot.data!;
                      
                      return RefreshIndicator(
                        color: const Color(0xFF7C4DFF),
                        backgroundColor: const Color(0xFF16151A),
                        onRefresh: () async {
                          await AppHaptics.pullRefresh();
                          _loadNews(forceRefresh: true);
                          await _newsFuture;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 100.0),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: articles.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 20),
                          itemBuilder: (context, index) {
                            final article = articles[index];
                            return _buildNewsCard(article);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return LiquidGlassContainer(
      onTap: () {
        AppHaptics.cardTap();
        if (article.link.isNotEmpty) {
          _launchUrl(article.link);
        }
      },
      borderRadius: 20,
      tintColor: const Color(0xFF14081B),
      tintOpacity: 0.65,
      enableBlur: true,
      blurSigma: 3.0,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.thumbnail.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                article.thumbnail,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: const Color(0xFF1C1124),
                  child: const Center(
                    child: Icon(Icons.satellite_alt_rounded, color: Color(0xFF382942), size: 48),
                  ),
                ),
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(article.category).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _getCategoryColor(article.category).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            article.category.name.toUpperCase(),
                            style: TextStyle(
                              color: _getCategoryColor(article.category),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF251C2B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article.sourceName.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF9871BA),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatTimeAgo(article.pubDate),
                      style: const TextStyle(
                        color: Color(0xFF6F667A),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    height: 1.3,
                  ),
                ),
                if (article.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    article.description.replaceAll(RegExp(r'<[^>]*>'), ''), // strip any HTML
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF908A99),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
