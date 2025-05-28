class Resource {
  static const Map<String, Map<String,String>> labelMaps = {
    'culturalResponsiveness': {
      'none': 'Not culturally specific to Hopi or Indigenous communities',
      'low': 'Low Cultural Responsiveness',
      'some': 'Some Cultural Responsiveness',
      'good': 'Good Cultural Responsiveness',
      'high': 'Specific resource for Hopi community'
    },
    'cost' : {
      'free': 'Free',
      'insurance_covered': 'Covered by insurance',
      'insurance_copay': 'Covered by insurance with copay',
      'income_scale': 'Sliding scale (income-based)',
      'donation': 'Pay what you can/donation-based',
      'payment_plan': 'Payment plans available',
      'subscription': 'Subscription',
      'fee': 'One-time fee',
      'free_trial': 'Free trial period'
    },
  };

  // safe access methods
  static Map<String, String>  getCategoryLabelMap(String category){
    return labelMaps[category] ?? {};
  }

  static String getLabel(String category, String key) {
    return labelMaps[category]?[key] ?? 'Unknown ${category}';
  }
}
