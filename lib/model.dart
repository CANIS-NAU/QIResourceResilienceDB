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
    }
  }
}

class Resource {
  // data fields
  final String? address;
  final String? agerange;
  final Attachment? attachments;
  final String? building;
  final String? city;
  final List<String>? cost;
  final String? createdBy;
  final DateTime? createdTime;
  final String? culturalResponsiveness;
  final String? dateAdded;
  final String? description;
  final bool isVisable;
  final String? location;
  final String? name;
  final String? phoneNumber;
  final List<String>? privacy;
  final String? resourceType;
  final Rubric? rubric;
  final String? state;
  final List<String>? tagline;
  final bool verified;
  final String? zipcode;

  // labels for display
  String get culturalResponsivenessLabel => 
    culturalResponsivenessLabels[culturalResponsiveness]
    ?? "Unrecognized Cultural Responsiveness value, no label found";

  String get costLabel =>
    costLabels[cost]
    ?? "Unrecognized Cost value, no label found";

  // default constructor
  Resource({
    this.address,
    this.agerange,
    this.attachments,
    this.building,
    this.city,
    this.cost = const [],
    this.createdBy,
    this.createdTime,
    this.culturalResponsiveness,
    this.dateAdded,
    this.description,
    this.isVisable,
    this.location,
    this.name,
    this.phoneNumber,
    this.privacy = const [],
    this.resourceType,
    this.rubric,
    this.state,
    this.tagline = const [],
    this.verified = false,
    this.zipcode,
  });

  // firestore => dart
  factory Resource.fromJson( Map<String, dynamic> json ) {
    return Resource(
      address: json["address"],
      agerange: json["agerange"],
      attachments: json["attachments"] != null 
        ? Attachment.fromJson( Map<String, dynamic>.from( json["attachments"] ) )
        : null,
      building: json["building"],
      city: json["city"],
      cost: List<String>.from( json["cost"] ?? [] ),
      createdBy: json["createdBy"],
      createdTime: json["createdTime"]?.toDate(),
      culturalResponsiveness: json["culturalResponsiveness"],
      dateAdded: json["dateAdded"],
      description: json["description"],
      isVisable: json["isVisible"],
      location: json["location"],
      name: json["name"],
      phoneNumber: json["phoneNumber"],
      privacy: List<String>.from( json["privacy"] ?? [] ),
      resourceType: json["resourceType"],
      rubric: json["rubric"] != null
        ? Rubric.fromJson( Map<String, dynamic>.from( json["rubric"] ) )
        : null,
      state: json["state"],
      tagline: json["tagline"],
    );
  }
  // dart => firestore
  Map<String, dynamic> toJson(){
    return {
      "address": address,
      "agerange": agerange,
      "attachments": attachments.toJson(),
      "building": building,
      "city": city,
      "cost": cost,
      "createdBy": createdBy,
      "createdTime": createdTime,
      "culturalResponsiveness": culturalResponsiveness,
      "dateAdded": dateAdded,
      "description": description,
      "isVisable": isVisable,
      "location": location,
      "name": name,
      "phoneNumber": phoneNumber,
      "privacy": privacy,
      "resourceType": resourceType,
      "rubric": rubric.toJson(),
      "state": state,
      "tagline": tagline,
    };
  }
  
  // TODO: add validation
  
  static const Map<String, String> culturalResponsivenessLabels = {
    'none': 'Not culturally specific to Hopi or Indigenous communities',
    'low': 'Low Cultural Responsiveness',
    'some': 'Some Cultural Responsiveness',
    'good': 'Good Cultural Responsiveness',
    'high': 'Specific resource for Hopi community'
  };
}