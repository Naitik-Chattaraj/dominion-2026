import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
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
                Padding(
                  padding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 10.0),
                  child: Text(
                    'Local Intelligence',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 20.0),
                  child: Text(
                    'Latest verified updates from around your area',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      color: Color(0xFF908A99),
                    ),
                  ),
                ),
                
                Expanded(
                  child: FutureBuilder<List<NewsArticle>>(
                    future: _newsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
                        );
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.0.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  color: Color(0xFF908A99),
                                  size: 48,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Unable to load latest intelligence.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF908A99),
                                    fontSize: 15.sp,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                LiquidGlassContainer(
                                  onTap: () {
                                    AppHaptics.cardTap();
                                    _loadNews(forceRefresh: true);
                                  },
                                  borderRadius: 14,
                                  tintColor: const Color(0xFF2C1638),
                                  tintOpacity: 0.85,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    'Retry Fetching',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
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
                          padding: EdgeInsets.fromLTRB(18.0.w, 0.0, 18.0.w, 140.0.h),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: articles.length,
                          separatorBuilder: (context, index) => SizedBox(height: 15.h),
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
      borderRadius: 16,
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              child: Image.network(
                article.thumbnail,
                height: 150.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150.h,
                  color: const Color(0xFF1C1124),
                  child: Center(
                    child: Icon(Icons.satellite_alt_rounded, color: Color(0xFF382942), size: 42),
                  ),
                ),
              ),
            ),
            
          Padding(
            padding: EdgeInsets.all(14.0.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
                          margin: EdgeInsets.only(right: 7.w),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(article.category).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(color: _getCategoryColor(article.category).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            article.category.name.toUpperCase(),
                            style: TextStyle(
                              color: _getCategoryColor(article.category),
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF251C2B),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Text(
                            article.sourceName.toUpperCase(),
                            style: TextStyle(
                              color: Color(0xFF9871BA),
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatTimeAgo(article.pubDate),
                      style: TextStyle(
                        color: Color(0xFF6F667A),
                        fontSize: 10.5.sp,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 9.h),
                Text(
                  article.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    height: 1.25.h,
                  ),
                ),
                if (article.description.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    article.description.replaceAll(RegExp(r'<[^>]*>'), ''), // strip any HTML
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF908A99),
                      fontSize: 12.sp,
                      fontFamily: 'Inter',
                      height: 1.35.h,
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
