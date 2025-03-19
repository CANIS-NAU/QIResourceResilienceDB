import 'package:flutter/material.dart';
import 'package:web_app/Analytics.dart';

class AnalyticsProvider extends ChangeNotifier {
  final HomeAnalytics _analytics = HomeAnalytics();

  // flag controlling whether or not to track link clicks
  bool _shouldTrackLinks = true;

  HomeAnalytics get analytics => _analytics;

  bool get shouldTrackLinks => _shouldTrackLinks;
  set shouldTrackLinks(bool value) {
    _shouldTrackLinks = value;
    notifyListeners(); 
  }

  void submitClickedLink(String type, Uri link, String resourceId) {
    if (_shouldTrackLinks) {
      _analytics.submitClickedLink(type, link, resourceId);
    }
  }
}