import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:xml/xml.dart';

enum SafetyCategory { crime, hazard, traffic, generalAlert }

class NewsArticle {
  final String title;
  final String pubDate;
  final String link;
  final String thumbnail;
  final String description;
  final String sourceName;
  final SafetyCategory category;

  NewsArticle({
    required this.title,
    required this.pubDate,
    required this.link,
    required this.thumbnail,
    required this.description,
    required this.sourceName,
    required this.category,
  });

  static SafetyCategory _categorize(String text) {
    final lower = text.toLowerCase();
    if (lower.contains(RegExp(r'murder|assault|crime|fight|police|robbery|arrest|thief|theft'))) {
      return SafetyCategory.crime;
    }
    if (lower.contains(RegExp(r'accident|traffic|roadblock|collision|detour|crash|highway'))) {
      return SafetyCategory.traffic;
    }
    if (lower.contains(RegExp(r'fire|flood|hazard|power outage|weather|storm|cyclone'))) {
      return SafetyCategory.hazard;
    }
    return SafetyCategory.generalAlert;
  }
  
  static bool _isRelevant(String text) {
     final lower = text.toLowerCase();
     return lower.contains(RegExp(r'murder|assault|crime|fight|police|robbery|arrest|thief|theft|accident|traffic|roadblock|collision|detour|crash|highway|fire|flood|hazard|power outage|weather|storm|cyclone|alert|warning|emergency'));
  }

  static String _selectDistinctThumbnail(
    XmlElement item,
    String title,
    String desc,
    SafetyCategory category, {
    int index = 0,
    Set<String>? usedUrls,
  }) {
    // 1. Curated, high-definition incident photography pools matching context and category
    final lower = '$title $desc'.toLowerCase();
    final int hash = title.codeUnits.fold<int>(0, (prev, elem) => (prev * 31 + elem) & 0x7FFFFFFF);

    final fireImages = [
      'https://images.unsplash.com/photo-1542385151-efd9000785a0?auto=format&fit=crop&q=80&w=1200', // Fire engine lights
      'https://images.unsplash.com/photo-1498084393753-b411b2d26b34?auto=format&fit=crop&q=80&w=1200', // Night emergency smoke
      'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&q=80&w=1200', // Firefighters operation
      'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&q=80&w=1200', // Emergency response convoy
      'https://images.unsplash.com/photo-1527786356703-4b100091cd2c?auto=format&fit=crop&q=80&w=1200', // Industrial smoke alert
      'https://images.unsplash.com/photo-1509114397022-ed747cca3f65?auto=format&fit=crop&q=80&w=1200', // Night emergency strobes
      'https://images.unsplash.com/photo-1577495508048-b635879837f1?auto=format&fit=crop&q=80&w=1200', // Fire rescue brigade
      'https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?auto=format&fit=crop&q=80&w=1200', // Hazmat hazard tape
      'https://images.unsplash.com/photo-1516796181074-bf453fbfa3e6?auto=format&fit=crop&q=80&w=1200', // Red emergency flare
      'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&q=80&w=1200', // Fire department gear
      'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&q=80&w=1200', // Night rescue team
      'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&q=80&w=1200', // Search & rescue squad
    ];

    final stormFloodImages = [
      'https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?auto=format&fit=crop&q=80&w=1200', // Rain and waterlogged streets
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=1200', // High coastal gale surge
      'https://images.unsplash.com/photo-1534088568595-a066f410bcda?auto=format&fit=crop&q=80&w=1200', // Severe thunderstorm lightning
      'https://images.unsplash.com/photo-1527482797697-8795b05a13fe?auto=format&fit=crop&q=80&w=1200', // Heavy deluge downpour
      'https://images.unsplash.com/photo-1516912481808-3406841bd33c?auto=format&fit=crop&q=80&w=1200', // Flash flood rainwater
      'https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?auto=format&fit=crop&q=80&w=1200', // Inclement tempest
      'https://images.unsplash.com/photo-1428592953211-077101b2021b?auto=format&fit=crop&q=80&w=1200', // Dense storm fog
      'https://images.unsplash.com/photo-1504608524841-42fe6f032b4b?auto=format&fit=crop&q=80&w=1200', // Dark supercell sky
      'https://images.unsplash.com/photo-1514632595-4944383f2737?auto=format&fit=crop&q=80&w=1200', // Monsoon rain sheet
      'https://images.unsplash.com/photo-1561553873-e8491a564fd0?auto=format&fit=crop&q=80&w=1200', // Cyclone storm wind
      'https://images.unsplash.com/photo-1513002749550-c59d786b8e6c?auto=format&fit=crop&q=80&w=1200', // Ominous thunderclouds
      'https://images.unsplash.com/photo-1530587191325-3db32d826c18?auto=format&fit=crop&q=80&w=1200', // Severe weather alert
    ];

    final trafficImages = [
      'https://images.unsplash.com/photo-1562309148-356a4b16da94?auto=format&fit=crop&q=80&w=1200', // Highway bottleneck detour
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&q=80&w=1200', // Night expressway traffic
      'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&q=80&w=1200', // Roadworks and detour cones
      'https://images.unsplash.com/photo-1543465077-db45d34b88a5?auto=format&fit=crop&q=80&w=1200', // Traffic congestion
      'https://images.unsplash.com/photo-1502877338535-766e1452684a?auto=format&fit=crop&q=80&w=1200', // Commuter highway slow
      'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?auto=format&fit=crop&q=80&w=1200', // Intersection detour hazard
      'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?auto=format&fit=crop&q=80&w=1200', // Street roadwork zone
      'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&q=80&w=1200', // Highway caution sign
      'https://images.unsplash.com/photo-1584438784894-089d6a62b8fa?auto=format&fit=crop&q=80&w=1200', // Emergency ambulance lights
      'https://images.unsplash.com/photo-1541888946425-d0fbb18086f6?auto=format&fit=crop&q=80&w=1200', // Heavy road construction
      'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&q=80&w=1200', // Highway flashing lights
      'https://images.unsplash.com/photo-1482029255085-35a4a48b7084?auto=format&fit=crop&q=80&w=1200', // Night car taillights
    ];

    final crimeImages = [
      'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&q=80&w=1200', // Blue and red emergency lights
      'https://images.unsplash.com/photo-1508847154043-be5407fcaa5a?auto=format&fit=crop&q=80&w=1200', // Police cruiser night patrol
      'https://images.unsplash.com/photo-1589578527966-fdac0f44566c?auto=format&fit=crop&q=80&w=1200', // Police line caution
      'https://images.unsplash.com/photo-1453873531674-2151bcd01707?auto=format&fit=crop&q=80&w=1200', // Law enforcement officer
      'https://images.unsplash.com/photo-1589994965851-a8f479c573a9?auto=format&fit=crop&q=80&w=1200', // Courthouse justice columns
      'https://images.unsplash.com/photo-1589391886645-d51941baf7fb?auto=format&fit=crop&q=80&w=1200', // Judicial legal gavel
      'https://images.unsplash.com/photo-1505664194779-8beaceb93744?auto=format&fit=crop&q=80&w=1200', // Lady of Justice bronze scale
      'https://images.unsplash.com/photo-1575517111478-7f6afd0973db?auto=format&fit=crop&q=80&w=1200', // Urban patrol watch
      'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&q=80&w=1200', // Tactical response squad
      'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&q=80&w=1200', // Police vehicle headlights
      'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?auto=format&fit=crop&q=80&w=1200', // Security briefing hall
      'https://images.unsplash.com/photo-1563986768609-322da13575f3?auto=format&fit=crop&q=80&w=1200', // Investigation file
    ];

    final generalImages = [
      'https://images.unsplash.com/photo-1546422904-90eab23c3d7e?auto=format&fit=crop&q=80&w=1200', // Public broadcast bulletin
      'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&q=80&w=1200', // Digital alert network
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=1200', // City urban safety
      'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&q=80&w=1200', // Metropolis emergency skyline
      'https://images.unsplash.com/photo-1444723121867-7a241cacace9?auto=format&fit=crop&q=80&w=1200', // City at dusk
      'https://images.unsplash.com/photo-1471922694854-ff1b63b20054?auto=format&fit=crop&q=80&w=1200', // Infrastructure monitoring
      'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&q=80&w=1200', // Municipal square
      'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&q=80&w=1200', // Emergency guidance
      'https://images.unsplash.com/photo-1508873696983-2df5293cb325?auto=format&fit=crop&q=80&w=1200', // City alert lights
      'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&q=80&w=1200', // Civil security team
      'https://images.unsplash.com/photo-1494783367193-149034c05e8f?auto=format&fit=crop&q=80&w=1200', // Surveillance cameras
      'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?auto=format&fit=crop&q=80&w=1200', // Downtown district
    ];

    List<String> primaryPool;
    if (lower.contains(RegExp(r'fire|flame|wildfire|blaze|explosion|burn'))) {
      primaryPool = fireImages;
    } else if (lower.contains(RegExp(r'flood|storm|rain|cyclone|weather|waterlog|downpour'))) {
      primaryPool = stormFloodImages;
    } else if (category == SafetyCategory.crime || lower.contains(RegExp(r'police|arrest|robbery|theft|investigation|warrant|shot|assault'))) {
      primaryPool = crimeImages;
    } else if (category == SafetyCategory.traffic || lower.contains(RegExp(r'traffic|crash|accident|road|highway|closure|detour'))) {
      primaryPool = trafficImages;
    } else if (category == SafetyCategory.hazard) {
      primaryPool = fireImages;
    } else {
      primaryPool = generalImages;
    }

    // Try finding an unused image in primary pool starting from offset
    final startOffset = (hash + index) % primaryPool.length;
    for (int i = 0; i < primaryPool.length; i++) {
      final candidate = primaryPool[(startOffset + i) % primaryPool.length];
      if (usedUrls == null || !usedUrls.contains(candidate)) {
        usedUrls?.add(candidate);
        return candidate;
      }
    }

    // If primary pool exhausted, search all combined pools
    final allImages = [
      ...crimeImages,
      ...trafficImages,
      ...fireImages,
      ...stormFloodImages,
      ...generalImages,
    ];
    final allOffset = (hash + index) % allImages.length;
    for (int i = 0; i < allImages.length; i++) {
      final candidate = allImages[(allOffset + i) % allImages.length];
      if (usedUrls == null || !usedUrls.contains(candidate)) {
        usedUrls?.add(candidate);
        return candidate;
      }
    }

    final fallback = primaryPool[startOffset];
    usedUrls?.add(fallback);
    return fallback;
  }

  factory NewsArticle.fromXml(XmlElement item, {int index = 0, Set<String>? usedUrls}) {
    final title = item.findElements('title').isNotEmpty ? item.findElements('title').first.innerText : 'Local News Event';
    final link = item.findElements('link').isNotEmpty ? item.findElements('link').first.innerText : '';
    final pubDate = item.findElements('pubDate').isNotEmpty ? item.findElements('pubDate').first.innerText : '';
    final description = item.findElements('description').isNotEmpty ? item.findElements('description').first.innerText : '';
    final sourceNode = item.findElements('source');
    final sourceName = sourceNode.isNotEmpty ? sourceNode.first.innerText : 'Google News';
    
    // Clean html tags and entities from description
    String cleanDesc = description.replaceAll(RegExp(r'<[^>]*>'), '');
    cleanDesc = cleanDesc
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    String cleanTitle = title
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();

    final category = _categorize('$cleanTitle $cleanDesc');
    final thumb = _selectDistinctThumbnail(
      item,
      cleanTitle,
      cleanDesc,
      category,
      index: index,
      usedUrls: usedUrls,
    );

    return NewsArticle(
      title: cleanTitle,
      pubDate: pubDate,
      link: link,
      thumbnail: thumb,
      description: cleanDesc,
      sourceName: sourceName,
      category: category,
    );
  }
}

class NewsService {
  static final NewsService _instance = NewsService._internal();
  static NewsService get instance => _instance;

  NewsService._internal();

  List<NewsArticle> _cachedNews = [];
  Position? _lastFetchedPosition;
  DateTime? _lastFetchedTime;
  String lastResolvedCity = "your area";
  Future<List<NewsArticle>>? _inFlightFuture;

  Future<List<NewsArticle>> fetchLocalNews({bool forceRefresh = false}) async {
    if (_inFlightFuture != null && !forceRefresh) {
      return _inFlightFuture!;
    }

    _inFlightFuture = _executeFetch(forceRefresh).whenComplete(() {
      _inFlightFuture = null;
    });

    return _inFlightFuture!;
  }

  Future<List<NewsArticle>> _executeFetch(bool forceRefresh) async {
    bool shouldFetch = forceRefresh;
    Position? currentPos;
    
    try {
      currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      
      if (_lastFetchedPosition == null || _lastFetchedTime == null) {
        shouldFetch = true;
      } else {
        final distance = Geolocator.distanceBetween(
          _lastFetchedPosition!.latitude,
          _lastFetchedPosition!.longitude,
          currentPos.latitude,
          currentPos.longitude,
        );
        if (distance > 5000) {
          shouldFetch = true;
        } else if (DateTime.now().difference(_lastFetchedTime!).inMinutes > 30) {
          shouldFetch = true;
        }
      }
    } catch (e) {
      // Permission denied or timeout
      shouldFetch = _cachedNews.isEmpty;
    }

    if (!shouldFetch && _cachedNews.isNotEmpty) {
      return _cachedNews;
    }

    // Try to get city name
    String city = "Chennai"; // fallback
    if (currentPos != null) {
      try {
        List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
          currentPos.latitude,
          currentPos.longitude,
        );
        if (placemarks.isNotEmpty) {
          city = placemarks.first.locality ?? placemarks.first.subLocality ?? "Chennai";
          lastResolvedCity = city;
        }
      } catch (e) {
        // Reverse geocoding failed
      }
    }

    try {
      // Fetch from Google News RSS
      final query = Uri.encodeComponent('$city AND (crime OR accident OR hazard OR police OR fire OR alert OR emergency)');
      final rssUrl = 'https://news.google.com/rss/search?q=$query&hl=en-IN&gl=IN&ceid=IN:en';
      
      final response = await http.get(Uri.parse(rssUrl)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        
        List<NewsArticle> parsedNews = [];
        final Set<String> usedThumbs = {};
        int itemIdx = 0;
        for (var item in items) {
          final article = NewsArticle.fromXml(item, index: itemIdx, usedUrls: usedThumbs);
          // Apply Regex relevance filter
          if (NewsArticle._isRelevant('${article.title} ${article.description}')) {
             parsedNews.add(article);
             itemIdx++;
          }
        }
        
        // Take top 15
        if (parsedNews.length > 15) {
          parsedNews = parsedNews.sublist(0, 15);
        }
        
        if (parsedNews.isNotEmpty) {
          _cachedNews = parsedNews;
          _lastFetchedPosition = currentPos;
          _lastFetchedTime = DateTime.now();
          return _cachedNews;
        }
      }
    } catch (e) {
      // Ignore network errors, fallback to mock/cache
    }

    if (_cachedNews.isEmpty) {
      _cachedNews = _getMockNews(city);
    }

    return _cachedNews;
  }

  List<NewsArticle> _getMockNews(String city) {
    return [
      NewsArticle(
        title: 'Increased Police Night Patrols Deployed around $city Corridors',
        pubDate: DateTime.now().subtract(const Duration(hours: 3)).toString(),
        link: 'https://news.google.com',
        thumbnail: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&q=80&w=1200',
        description: 'Joint vehicular check posts installed to curb speeding and night theft.',
        sourceName: '$city Police',
        category: SafetyCategory.crime,
      ),
      NewsArticle(
        title: 'Roadblock Reported due to ongoing metro expansion in $city',
        pubDate: DateTime.now().subtract(const Duration(hours: 1)).toString(),
        link: 'https://news.google.com',
        thumbnail: 'https://images.unsplash.com/photo-1562309148-356a4b16da94?auto=format&fit=crop&q=80&w=1200',
        description: 'Traffic diversions expected with heavy police deployment.',
        sourceName: '$city Traffic',
        category: SafetyCategory.traffic,
      ),
      NewsArticle(
        title: 'Scheduled Power Outage in $city for Grid Maintenance',
        pubDate: DateTime.now().subtract(const Duration(hours: 2)).toString(),
        link: 'https://news.google.com',
        thumbnail: 'https://images.unsplash.com/photo-1498084393753-b411b2d26b34?auto=format&fit=crop&q=80&w=1200',
        description: 'TNEB informs public of transformer overhaul between 9 AM and 4 PM.',
        sourceName: 'Electricity Board',
        category: SafetyCategory.hazard,
      ),
    ];
  }
}
