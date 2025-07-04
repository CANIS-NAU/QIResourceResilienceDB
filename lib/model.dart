import 'package:web_app/file_attachments.dart';
import 'package:web_app/events/schedule.dart';

class Rubric {
  final int? accurate;
  final String? additionalComments;
  final List<String> ageBalance;
  final int? authenticity;
  final int? consistency;
  final int? culturallyGrounded;
  final int? current;
  final int? experienceBalance;
  final List<String> genderBalance;
  final int? language;
  final int? modularizable;
  final int? notMorallyOffensive;
  final int? productionValue;
  final int? relevance;
  final int? socialSupport;
  final int? totalScore;
  final int? trustworthySource;

  // default constructor
  Rubric({
    required this.accurate,
    required this.additionalComments,
    required this.ageBalance,
    required this.authenticity,
    required this.consistency,
    required this.culturallyGrounded,
    required this.current,
    required this.experienceBalance,
    required this.genderBalance,
    required this.language,
    required this.modularizable,
    required this.notMorallyOffensive,
    required this.productionValue,
    required this.relevance,
    required this.socialSupport,
    required this.totalScore,
    required this.trustworthySource,
  });
  // firestore => dart
  factory Rubric.fromJson( Map<String, dynamic> json ) {
    return Rubric(
      accurate: json["accurate"],
      additionalComments: json["additionalComments"],
      ageBalance: List<String>.from( json["ageBalance"] ),
      authenticity: json["authenticity"],
      consistency: json["consistency"],
      culturallyGrounded: json["culturallyGrounded"],
      current: json["current"],
      experienceBalance: json["experienceBalance"],
      genderBalance: List<String>.from( json["genderBalance"] ),
      language: json["language"],
      modularizable: json["modularizable"],
      notMorallyOffensive: json["notMorallyOffensive"],
      productionValue: json["productionValue"],
      relevance: json["relevance"],
      socialSupport: json["socialSupport"],
      totalScore: json["totalScore"],
      trustworthySource: json["trustworthySource"],
    );
  }

  // dart => firestore
  Map<String, dynamic> toJson(){
    return{
      "accurate": accurate,
      "additionalComments": additionalComments,
      "ageBalance": ageBalance,
      "authenticity": authenticity,
      "consistency": consistency,
      "culturallyGrounded": culturallyGrounded,
      "current": current,
      "experienceBalance": experienceBalance,
      "genderBalance": genderBalance,
      "language": language,
      "modularizable": modularizable,
      "notMorallyOffensive": notMorallyOffensive,
      "productionValue": productionValue,
      "relevance": relevance,
      "socialSupport": socialSupport,
      "totalScore": totalScore,
      "trustworthySource": trustworthySource,
    };
  }
}

class Resource {

  final String? address;
  final String? agerange;
  final List<Attachment>? attachments;
  final String? building;
  final String? city;
  final List<String>? cost;
  final String? createdBy;
  final DateTime? createdTime;
  final String? culturalResponsiveness;
  final String? dateAdded;
  final String? description;
  final List<String>? healthFocus;
  final String id;
  final bool isVisable;
  final String? location;
  final String? name;
  final String? phoneNumber;
  final List<String>? privacy;
  final String? resourceType;
  final Rubric? rubric;
  final Schedule? schedule;
  final String? state;
  final List<String>? tagline;
  final bool verified;
  final String? zipcode;

  // Default constructor
  Resource({
    this.address,
    this.agerange,
    this.attachments = const [],
    this.building,
    this.city,
    this.cost = const [],
    this.createdBy,
    this.createdTime,
    this.culturalResponsiveness,
    this.dateAdded,
    this.description,
    this.healthFocus = const [],
    this.id = "",
    this.isVisable = true,
    this.location,
    this.name,
    this.phoneNumber,
    this.privacy = const [],
    this.resourceType,
    this.rubric,
    this.schedule,
    this.state,
    this.tagline = const [],
    this.verified = false,
    this.zipcode,
  });

  // Serialize from JSON
  factory Resource.fromJson(Map<String, dynamic> json, String id) {
    return Resource(
      address: json["address"],
      agerange: json["agerange"],
      attachments: List.from(json["attachments"] ?? [])
          .map((x) => Attachment.fromJson(x))
          .toList(),
      building: json["building"],
      city: json["city"],
      cost: List<String>.from(json["cost"] ?? []),
      createdBy: json["createdBy"],
      createdTime: json["createdTime"]?.toDate(),
      culturalResponsiveness: json["culturalResponsiveness"],
      dateAdded: json["dateAdded"],
      description: json["description"],
      healthFocus: List<String>.from(json["healthFocus"] ?? []),
      id: id,
      isVisable: json["isVisable"],
      location: json["location"],
      name: json["name"],
      phoneNumber: json["phoneNumber"],
      privacy: List<String>.from(json["privacy"] ?? []),
      resourceType: json["resourceType"],
      rubric: json["rubric"] != null
          ? Rubric.fromJson(Map<String, dynamic>.from(json["rubric"]))
          : null,
      schedule: json["schedule"] != null
          ? Schedule.fromJson(Map<String, dynamic>.from(json["schedule"]))
          : null,
      state: json["state"],
      tagline: List<String>.from(json["tagline"] ?? [])
          .map((x) => x.toString())
          .toList(),
      verified: json["verified"] ?? false,
      zipcode: json["zipcode"],
    );
  }

  // Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      "address": address,
      "agerange": agerange,
      "attachments": (attachments ?? []).map((a) => a.toJson()).toList(),
      "building": building,
      "city": city,
      "cost": cost,
      "createdBy": createdBy,
      "createdTime": createdTime,
      "culturalResponsiveness": culturalResponsiveness,
      "dateAdded": dateAdded,
      "description": description,
      "healthFocus": healthFocus,
      "isVisable": isVisable,
      "location": location,
      "name": name,
      "phoneNumber": phoneNumber,
      "privacy": privacy,
      "resourceType": resourceType,
      "rubric": rubric?.toJson(),
      "schedule": schedule?.toJson(),
      "state": state,
      "tagline": tagline,
      "verified": verified,
      "zipcode": zipcode,
    };
  }

  // Computed properties
  String get fullAddress {
    final parts = [address, building, city, state, zipcode]
      .where((part) => part != null && part!.isNotEmpty).toList();
    return parts.join(', ');
  }

  // Labels for string values
  String get resourceTypeLabel =>
      getLabelFromString(resourceType, resourceTypeLabels) ?? "";

  String get ageLabel => getLabelFromString(agerange, ageLabels) ?? "";

  String get culturalResponsivenessLabel =>
      getLabelFromString(culturalResponsiveness, culturalResponsivenessLabels) ??
      "";

  // Labels for list values
  String get costLabel => getLabelFromList(cost, costLabels) ?? "";

  String get privacyLabel => getLabelFromList(privacy, privacyLabels) ?? "";

  String get healthFocusLabel => getLabelFromList(healthFocus, healthFocusLabels) ?? "";

  // Helper methods to get labels from string or list values
  String? getLabelFromString(String? value, Map<String, String> labels) {
    if (value == null || value.isEmpty) return null;
    return labels[value] ?? "Unrecognized value";
  }

  String? getLabelFromList(List<String>? values, Map<String, String> labels) {
    if (values == null || values.isEmpty) return null;
    return values.map((v) => labels[v] ?? "Unrecognized value").join(", ");
  }

  // Validate the resource fields
  /// Returns a list of error messages for any invalid fields.
  List<String> validateResource() {
    final List<String> errors = [];

    // fields common to all resources
    if (name == "") errors.add("Resource name is required.");
    if (description == "") errors.add("Resource description is required.");
    if (location == "") errors.add("Resource link is required.");
    if (resourceType == "") errors.add("Resource type is required.");

    if (privacy?.isEmpty ?? true) errors.add("At least one privacy option must be selected.");
    if (cost?.isEmpty ?? true) errors.add("At least one cost option must be selected.");

    // resource type specific fields
    if (resourceType == "In Person") {
      if (address == "") errors.add("An address is required for in person resources.");
      if (city == "") errors.add("A city is required for in person resources.");
      if (state == "") errors.add("A state is required for in person resources.");
      if (zipcode == "") errors.add("A zip code is required for in person resources.");
    }

    if (resourceType == "Hotline" || resourceType == "In Person") {
      if (phoneNumber == "") errors.add("A phone number is requred for in person/hotline resources.");
    }

    if (resourceType == "Event" && schedule == null) errors.add("A schedule is required for events.");

    return errors;
  }

  // Returns a set of visible fields based on the resource type.
  Set<String> visibleFields() {
    switch (resourceType) {
      case 'In Person':
        return {
          "description",
          "resourceType",
          "privacy",
          "culturalResponsiveness",
          "cost",
          "healthFocus",
          "address",
          "building",
          "city",
          "state",
          "zipcode",
          "phoneNumber",
          "location",
          "attachments",
        };
      case 'Hotline':
        return {
          "description",
          "resourceType",
          "privacy",
          "culturalResponsiveness",
          "cost",
          "healthFocus",
          "phoneNumber",
          "location",
          "attachments",
        };
      case 'Online':
      case 'Podcast':
      case 'App':
      case 'PDF':
      case 'Game':
      case 'Movement-based Activity':
        return {
          "description",
          "resourceType",
          "privacy",
          "culturalResponsiveness",
          "cost",
          "healthFocus",
          "location",
          "attachments",
        };
      case 'Event':
        return {
          "description",
          "resourceType",
          "schedule",
          "privacy",
          "culturalResponsiveness",
          "cost",
          "healthFocus",
          "address",
          "location",
          "attachments",
        };
      default:
        return {
          "description",
          "resourceType",
          "privacy",
          "culturalResponsiveness",
          "cost",
          "healthFocus",
          "address",
          "phoneNumber",
          "location",
          "attachments",
        };
    }
  }

  // Maps for associating string values with front-facing labels
  static Map<String, String> culturalResponsivenessLabels = Map.unmodifiable({
    'none': 'Not culturally specific to Hopi or Indigenous communities',
    'low': 'Low Cultural Responsiveness',
    'some': 'Some Cultural Responsiveness',
    'good': 'Good Cultural Responsiveness',
    'high': 'Specific resource for Hopi community'
  });

  static Map<String, String> costLabels = Map.unmodifiable({
    'free': 'Free',
    'insurance_covered': 'Covered by insurance',
    'insurance_copay': 'Covered by insurance with copay',
    'income_scale': 'Sliding scale (income-based)',
    'donation': 'Pay what you can/donation-based',
    'payment_plan': 'Payment plans available',
    'subscription': 'Subscription',
    'fee': 'One-time fee',
    'free_trial': 'Free trial period'
  });

  static Map<String, String> resourceTypeLabels = Map.unmodifiable({
    'In Person': 'In Person',
    'Hotline': 'Hotline',
    'Online': 'Online',
    'Podcast': 'Podcast',
    'App': 'App',
    'Event': 'Event',
    'PDF': 'PDF',
    'Game': 'Game',
    'Movement-based Activity': 'Movement-based Activity',
  });

  static Map<String, String> ageLabels = Map.unmodifiable({
    'Under 18': 'Under 18',
    '18-24': '18-24',
    '24-65': '24-65',
    '65+': '65+',
    'All ages': 'All ages'
  });

  static Map<String, String> privacyLabels = Map.unmodifiable({
    'HIPAA Compliant': 'HIPAA Compliant',
    'Anonymous': 'Anonymous',
    'Mandatory Reporting': 'Mandatory Reporting',
    'None Stated': 'None Stated',
  });

  static Map<String, String> healthFocusLabels = Map.unmodifiable({
    'Anxiety': 'Anxiety',
    'Depression': 'Depression',
    'Stress Management': 'Stress Management',
    'Substance Abuse': 'Substance Abuse',
    'Grief and Loss': 'Grief and Loss',
    'Trama and PTSD': 'Trama and PTSD',
    'Suicide Prevention': 'Suicide Prevention',
  });
}