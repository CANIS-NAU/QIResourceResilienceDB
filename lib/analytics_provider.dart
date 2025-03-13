import 'package:flutter/material.dart';
import 'package:web_app/Analytics.dart';

class AnalyticsProvider extends ChangeNotifier {
  final HomeAnalytics _analytics = HomeAnalytics();

  HomeAnalytics get analytics => _analytics;

  void submitClickedLink(String type, Uri link, String resourceId) {
    _analytics.submitClickedLink(type, link, resourceId);
  }
}