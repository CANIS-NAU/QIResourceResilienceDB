import 'package:web_app/file_attachments.dart';
import 'package:web_app/events/schedule.dart';

class Rubric {
  // Preliminary rating fields
  final bool? appropriate;
  final bool? avoidsAgeism;
  final bool? avoidsAppropriation;
  final bool? avoidsCondescension;
  final bool? avoidsRacism;
  final bool? avoidsSexism;
  final bool? avoidsStereotyping;
  final bool? avoidsVulgarity;

  // Description fields
  final List<String>? accessibilityFeatures;
  final String? additionalComments;
  final List<String>? ageBalance;
  final List<String>? genderBalance;
  final List<String>? lifeExperiences;
  final bool? queerSexualitySpecific;

  // Scoring fields
  final int? contentAccuracy;
  final int? contentCurrentness;
  final int? contentTrustworthiness;
  final int? culturalGroundednessHopi;
  final int? culturalGroundednessIndigenous;

  // Metadata
  final String? reviewedBy;
  final DateTime? reviewTime;

  // Computed fields
  int get totalScore {
    return (culturalGroundednessHopi ?? 0) + (culturalGroundednessIndigenous ?? 0)
        + (contentAccuracy ?? 0) + (contentCurrentness ?? 0) + (contentTrustworthiness ?? 0);
  }

  List<String> get accessibilityFeaturesLabel {
    if (accessibilityFeatures == null || accessibilityFeatures!.isEmpty) {
      return ["No accessibility features specified"];
    }
    return accessibilityFeatures!.map((e) => 
        Rubric.accessibilityLabels[e] ?? "Unrecognized feature: $e").toList();
  }

  List<String> get ageBalanceLabel {
    if (ageBalance == null || ageBalance!.isEmpty) {
      return ["No age balance specified"];
    }
    return ageBalance!.map((e) => Resource.ageLabels[e] ?? "Unrecognized age: $e").toList();
  }

  List<String> get genderBalanceLabel {
    if (genderBalance == null || genderBalance!.isEmpty) {
      return ["No gender balance specified"];
    }
    return genderBalance!.map((e) => Rubric.genderLabels[e] ?? "Unrecognized gender: $e").toList();
  }

  List<String> get lifeExperiencesLabel {
    if (lifeExperiences == null || lifeExperiences!.isEmpty) {
      return ["No life experiences specified"];
    }
    return lifeExperiences!.map((e) => Rubric.lifeExperienceLabels[e] ?? "Unrecognized experience: $e").toList();
  }

  // default constructor
  Rubric({
    this.appropriate,
    this.avoidsAgeism,
    this.avoidsAppropriation,
    this.avoidsCondescension,
    this.avoidsRacism,
    this.avoidsSexism,
    this.avoidsStereotyping,
    this.avoidsVulgarity,

    this.accessibilityFeatures,
    this.additionalComments,
    this.ageBalance,
    this.genderBalance,
    this.lifeExperiences,
    this.queerSexualitySpecific,

    this.contentAccuracy,
    this.contentCurrentness,
    this.contentTrustworthiness,
    this.culturalGroundednessHopi,
    this.culturalGroundednessIndigenous,

    this.reviewedBy,
    this.reviewTime,
  });
  // firestore => dart
  factory Rubric.fromJson(Map<String, dynamic> json) {
    return Rubric(
      accessibilityFeatures: json["accessibilityFeatures"] != null ? List<String>.from(json["accessibilityFeatures"]) : null,
      additionalComments: json["additionalComments"],
      ageBalance: json["ageBalance"] != null ? List<String>.from(json["ageBalance"]) : null,
      appropriate: json["appropriate"] is bool ? json["appropriate"] : null,
      avoidsAgeism: json["avoidsAgeism"] is bool ? json["avoidsAgeism"] : null,
      avoidsAppropriation: json["avoidsAppropriation"] is bool ? json["avoidsAppropriation"] : null,
      avoidsCondescension: json["avoidsCondescension"] is bool ? json["avoidsCondescension"] : null,
      avoidsRacism: json["avoidsRacism"] is bool ? json["avoidsRacism"] : null,
      avoidsSexism: json["avoidsSexism"] is bool ? json["avoidsSexism"] : null,
      avoidsStereotyping: json["avoidsStereotyping"] is bool ? json["avoidsStereotyping"] : null,
      avoidsVulgarity: json["avoidsVulgarity"] is bool ? json["avoidsVulgarity"] : null,
      contentAccuracy: json["contentAccurate"],
      contentCurrentness: json["contentCurrentness"],
      contentTrustworthiness: json["contentTrustworthiness"],
      culturalGroundednessHopi: json["culturalGroundednessHopi"],
      culturalGroundednessIndigenous: json["culturalGroundednessIndigenous"],
      genderBalance: json["genderBalance"] != null ? List<String>.from(json["genderBalance"]) : null,
      lifeExperiences: json["lifeExperiences"] != null ? List<String>.from(json["lifeExperiences"]) : null,
      queerSexualitySpecific: json["queerSexualitySpecific"],
      reviewedBy: json["reviewedBy"],
      reviewTime: json["reviewTime"] != null ? json["reviewTime"].toDate() : null,
    );
  }
  

  // dart => firestore
  Map<String, dynamic> toJson() {
    return {
      "accessibilityFeatures": accessibilityFeatures,
      "additionalComments": additionalComments,
      "ageBalance": ageBalance,
      "appropriate": appropriate,
      "avoidsAgeism": avoidsAgeism,
      "avoidsAppropriation": avoidsAppropriation,
      "avoidsCondescension": avoidsCondescension,
      "avoidsRacism": avoidsRacism,
      "avoidsSexism": avoidsSexism,
      "avoidsStereotyping": avoidsStereotyping,
      "avoidsVulgarity": avoidsVulgarity,
      "contentAccuracy": contentAccuracy,
      "contentCurrentness": contentCurrentness,
      "contentTrustworthiness": contentTrustworthiness,
      "culturalGroundednessHopi": culturalGroundednessHopi,
      "culturalGroundednessIndigenous": culturalGroundednessIndigenous,
      "genderBalance": genderBalance,
      "lifeExperiences": lifeExperiences,
      "queerSexualitySpecific": queerSexualitySpecific,
      "reviewedBy": reviewedBy,
      "reviewTime": reviewTime,
    };
  }
  static Map<String, String> genderLabels = Map.unmodifiable({
    'Female': 'Female',
    'Male': 'Male',
    'Non-binary': 'Non-binary',
    'Other (please specify in comments)': 'Other (please specify in comments)',
  });

  static Map<String, String> lifeExperienceLabels = Map.unmodifiable({
    'Specific to houseless or unsheltered relatives': 'Specific to houseless or unsheltered relatives',
    'Specific to parents or guardians': 'Specific to parents or guardians',
    'Specific to grandparents': 'Specific to grandparents',
    'Specific to college students': 'Specific to college students',
    'Specific to people living away from home (e.g., college students or people living away from Hopi)': 'Specific to people living away from home (e.g., college students or people living away from Hopi)'
  });
  static Map<String, String> accessibilityLabels = Map.unmodifiable({
    'Visually Impaired': 'Resource is accessible to people who are visually impaired.',
    'Hearing Impaired': 'Resource is accessible to people who are hearing impaired.',
    'Mobility Challenges': 'Resource is accessible for people with mobility challenges (only applicable for in-person resources).',
    'Neurodivergent': 'Resource offers accessibility features for people who are neurodivergent.',
    'Sober Living Facility': 'Resource is related to a sober living facility, which has been verified by ADHS and AHCCCS.',
  });
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
  bool isDeleted;
  final String? location;
  final String? name;
  final String? phoneNumber;
  final List<String>? privacy;
  final String? resourceType;
  Rubric? rubric;
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
    this.isDeleted = false,
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
      isVisable: json["isVisable"] is bool ? json["isVisable"] : false,
      //isDeleted: json["isDeleted"],
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
      "isDeleted": isDeleted,
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