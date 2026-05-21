class MoverReview {
  final String author;
  final String text;
  final String category; // fragile, hidden_charges, punctuality, general
  final String sentiment; // positive, negative
  final String date;

  const MoverReview({
    required this.author,
    required this.text,
    required this.category,
    required this.sentiment,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'author': author,
        'text': text,
        'category': category,
        'sentiment': sentiment,
        'date': date,
      };
}

class MoverProvider {
  final String id;
  final String name;
  final String city;
  final String vehicleType;
  final double basePrice;
  final double rating;
  final int reviewCount;
  final double multiplier; // Price multiplier
  final String speciality;
  
  // Provenance Metadata
  final String sourceUrl;
  final String sourceType; // Google Maps, OLX, Company Website, Fictional
  final String ratingSource;
  final String reviewCountSource;
  final String lastUpdated;
  final double confidenceScore;
  final bool isLiveSourced; // false for MVP curated dataset
  final String reviewType; // "synthetic/mock review samples"
  final bool isRegistered; // Registered Partner on SafeShift vs Publicly Discovered
  
  // Contactability Status
  final bool hasPhone;
  final bool hasWebsite;
  final String hasWhatsApp; // "yes", "no", "unknown"
  final String contactMethod; // "call", "WhatsApp draft", "website", "simulated demo response"

  final List<MoverReview> reviews;
  final String agentVerdict;

  // Equipment & Crew Checklist
  final bool hasBlankets;
  final bool hasBubbleWrap;
  final bool hasCartons;
  final bool hasTape;
  final bool hasTrolley;
  final bool hasStraps;
  final bool hasTools;
  final bool hasDisassemblyTools;
  final int crewCount;
  final bool applianceExperience;

  const MoverProvider({
    required this.id,
    required this.name,
    required this.city,
    required this.vehicleType,
    required this.basePrice,
    required this.rating,
    required this.reviewCount,
    required this.multiplier,
    required this.speciality,
    required this.sourceUrl,
    required this.sourceType,
    required this.ratingSource,
    required this.reviewCountSource,
    required this.lastUpdated,
    required this.confidenceScore,
    required this.isLiveSourced,
    required this.reviewType,
    required this.isRegistered,
    required this.hasPhone,
    required this.hasWebsite,
    required this.hasWhatsApp,
    required this.contactMethod,
    required this.reviews,
    required this.agentVerdict,
    required this.hasBlankets,
    required this.hasBubbleWrap,
    required this.hasCartons,
    required this.hasTape,
    required this.hasTrolley,
    required this.hasStraps,
    required this.hasTools,
    required this.hasDisassemblyTools,
    required this.crewCount,
    required this.applianceExperience,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'vehicleType': vehicleType,
        'basePrice': basePrice,
        'rating': rating,
        'reviewCount': reviewCount,
        'multiplier': multiplier,
        'speciality': speciality,
        'sourceUrl': sourceUrl,
        'sourceType': sourceType,
        'ratingSource': ratingSource,
        'reviewCountSource': reviewCountSource,
        'lastUpdated': lastUpdated,
        'confidenceScore': confidenceScore,
        'isLiveSourced': isLiveSourced,
        'reviewType': reviewType,
        'isRegistered': isRegistered,
        'hasPhone': hasPhone,
        'hasWebsite': hasWebsite,
        'hasWhatsApp': hasWhatsApp,
        'contactMethod': contactMethod,
        'reviews': reviews.map((r) => r.toJson()).toList(),
        'agentVerdict': agentVerdict,
        'hasBlankets': hasBlankets,
        'hasBubbleWrap': hasBubbleWrap,
        'hasCartons': hasCartons,
        'hasTape': hasTape,
        'hasTrolley': hasTrolley,
        'hasStraps': hasStraps,
        'hasTools': hasTools,
        'hasDisassemblyTools': hasDisassemblyTools,
        'crewCount': crewCount,
        'applianceExperience': applianceExperience,
      };
}

final List<MoverProvider> localMoversDatabase = [
  MoverProvider(
    id: "p1",
    name: "Reliable Packers and Movers",
    city: "Rawalpindi/Islamabad",
    vehicleType: "Shahzor Loader",
    basePrice: 6000,
    rating: 4.8,
    reviewCount: 125,
    multiplier: 1.15,
    speciality: "Heavy appliances & complete house shifting",
    sourceUrl: "https://www.google.com/maps/place/Reliable+Packers+and+Movers+and+Goods+Transport+Company/",
    sourceType: "Google Maps / Places",
    ratingSource: "Google Places API APIv2",
    reviewCountSource: "Google Places API APIv2",
    lastUpdated: "2026-05-18",
    confidenceScore: 0.95,
    isLiveSourced: false,
    reviewType: "synthetic/mock review samples",
    isRegistered: true,
    hasPhone: true,
    hasWebsite: false,
    hasWhatsApp: "yes",
    contactMethod: "simulated demo response",
    reviews: [
      MoverReview(
        author: "Asim Khan",
        text: "My shifting experience was completely hassle-free! Fragile items were double wrapped.",
        category: "fragile",
        sentiment: "positive",
        date: "2 weeks ago",
      ),
      MoverReview(
        author: "Sobia Ahmed",
        text: "Great work with packing the fridge and washing machine. No scratches.",
        category: "general",
        sentiment: "positive",
        date: "1 month ago",
      ),
      MoverReview(
        author: "Bilal Butt",
        text: "Punctual crew, but they charged slightly extra for parking distance.",
        category: "punctuality",
        sentiment: "positive",
        date: "2 months ago",
      ),
    ],
    agentVerdict: "Strong candidate. Sourced from Google Maps with 125 reviews. Excellent history with heavy appliance packing. Highly reliable but has minor complaints about parking distance extra charges.",
    hasBlankets: true,
    hasBubbleWrap: true,
    hasCartons: true,
    hasTape: true,
    hasTrolley: true,
    hasStraps: true,
    hasTools: true,
    hasDisassemblyTools: false,
    crewCount: 3,
    applianceExperience: true,
  ),
  MoverProvider(
    id: "p2",
    name: "Costa Logistics",
    city: "Rawalpindi/Islamabad",
    vehicleType: "Mazda Truck",
    basePrice: 8500,
    rating: 4.7,
    reviewCount: 45,
    multiplier: 1.25,
    speciality: "Premium packing & furniture dismantling",
    sourceUrl: "https://costalogistics.com.pk/",
    sourceType: "Company Website",
    ratingSource: "Google Maps search & website reviews",
    reviewCountSource: "Google Places listing",
    lastUpdated: "2026-05-15",
    confidenceScore: 0.90,
    isLiveSourced: false,
    reviewType: "synthetic/mock review samples",
    isRegistered: false,
    hasPhone: true,
    hasWebsite: true,
    hasWhatsApp: "yes",
    contactMethod: "WhatsApp draft",
    reviews: [
      MoverReview(
        author: "Rehan Siddiqui",
        text: "Very professional team. They dismantled the wooden king bed and fixed it back perfectly in the new house.",
        category: "general",
        sentiment: "positive",
        date: "3 days ago",
      ),
      MoverReview(
        author: "Amina Alvi",
        text: "Highly recommend for complete home moves. Wrapped glass tables very carefully in bubble wrap.",
        category: "fragile",
        sentiment: "positive",
        date: "3 weeks ago",
      ),
      MoverReview(
        author: "Faisal Shah",
        text: "Cost is slightly high but service quality matches the premium. Safe and secure.",
        category: "general",
        sentiment: "positive",
        date: "1 month ago",
      ),
    ],
    agentVerdict: "Premium mover with established website and registered transport. Sourced from Costa Logistics website & Google Places. High confidence. Best for dismantling luxury double beds and delicate mirrors. Premium price markup applies.",
    hasBlankets: true,
    hasBubbleWrap: true,
    hasCartons: true,
    hasTape: true,
    hasTrolley: true,
    hasStraps: true,
    hasTools: true,
    hasDisassemblyTools: true,
    crewCount: 4,
    applianceExperience: true,
  ),
  MoverProvider(
    id: "p3",
    name: "Zain Packers & Movers",
    city: "Rawalpindi/Islamabad",
    vehicleType: "Suzuki Pickup",
    basePrice: 4000,
    rating: 4.5,
    reviewCount: 18,
    multiplier: 1.05,
    speciality: "Small room & apartment shifting",
    sourceUrl: "https://www.olx.com.pk/item/packers-movers-iid-1087453715",
    sourceType: "OLX Classifieds",
    ratingSource: "OLX Seller Ratings",
    reviewCountSource: "OLX feedback counters",
    lastUpdated: "2026-05-19",
    confidenceScore: 0.82,
    isLiveSourced: false,
    reviewType: "synthetic/mock review samples",
    isRegistered: false,
    hasPhone: true,
    hasWebsite: false,
    hasWhatsApp: "unknown",
    contactMethod: "WhatsApp draft",
    reviews: [
      MoverReview(
        author: "Kamran Malik",
        text: "Good service across Bahria Town. Quick and cheap loader.",
        category: "general",
        sentiment: "positive",
        date: "1 week ago",
      ),
      MoverReview(
        author: "Zahid Qureshi",
        text: "A bit delayed by 30 mins because of traffic jam at DHA gate, but overall helpful crew.",
        category: "punctuality",
        sentiment: "negative",
        date: "2 weeks ago",
      ),
      MoverReview(
        author: "Hassan Raza",
        text: "Minor scratch on my side table but they handled the TV safely.",
        category: "fragile",
        sentiment: "negative",
        date: "1 month ago",
      ),
    ],
    agentVerdict: "Cost-effective choice for small load moves in Bahria/DHA. Sourced from OLX. Good ratings, but has minor risk of delays at gated security checkpoints and occasional scratches on un-wrapped side tables.",
    hasBlankets: false,
    hasBubbleWrap: false,
    hasCartons: true,
    hasTape: true,
    hasTrolley: false,
    hasStraps: true,
    hasTools: true,
    hasDisassemblyTools: false,
    crewCount: 2,
    applianceExperience: false,
  ),
  MoverProvider(
    id: "p4",
    name: "Marshall Packers",
    city: "Rawalpindi/Islamabad",
    vehicleType: "Shahzor Loader",
    basePrice: 5500,
    rating: 4.4,
    reviewCount: 11,
    multiplier: 1.10,
    speciality: "Local Relocation",
    sourceUrl: "https://www.google.com/maps/place/I+Pack+Packers+and+Movers/",
    sourceType: "Google Maps / Places",
    ratingSource: "Google Maps places listing search",
    reviewCountSource: "Google Reviews count",
    lastUpdated: "2026-05-02",
    confidenceScore: 0.80,
    isLiveSourced: false,
    reviewType: "synthetic/mock review samples",
    isRegistered: false,
    hasPhone: true,
    hasWebsite: false,
    hasWhatsApp: "unknown",
    contactMethod: "WhatsApp draft",
    reviews: [
      MoverReview(
        author: "Yasir Arafat",
        text: "Safe handling of my LED TV and kitchen utensils. Decent packing.",
        category: "fragile",
        sentiment: "positive",
        date: "3 weeks ago",
      ),
      MoverReview(
        author: "Maria Khan",
        text: "They loaded everything safely. No hidden charges were demanded.",
        category: "hidden_charges",
        sentiment: "positive",
        date: "1 month ago",
      ),
    ],
    agentVerdict: "Mid-tier verified provider. Sourced from Google Maps. No hidden charges complaints. Reasonable rates.",
    hasBlankets: true,
    hasBubbleWrap: false,
    hasCartons: true,
    hasTape: true,
    hasTrolley: true,
    hasStraps: true,
    hasTools: true,
    hasDisassemblyTools: false,
    crewCount: 3,
    applianceExperience: true,
  ),
  MoverProvider(
    id: "p5",
    name: "Budget Loaderz",
    city: "Rawalpindi/Islamabad",
    vehicleType: "Suzuki Pickup",
    basePrice: 3000,
    rating: 3.8,
    reviewCount: 14,
    multiplier: 0.85,
    speciality: "Cheap no-frills transport",
    sourceUrl: "None (Fictional mock)",
    sourceType: "Fictional/Mock",
    ratingSource: "Mock ratings for baseline evaluation",
    reviewCountSource: "Mock reviews counter",
    lastUpdated: "2026-05-20",
    confidenceScore: 0.40,
    isLiveSourced: false,
    reviewType: "synthetic/mock review samples",
    isRegistered: false,
    hasPhone: false,
    hasWebsite: false,
    hasWhatsApp: "no",
    contactMethod: "WhatsApp draft",
    reviews: [
      MoverReview(
        author: "Haris Jamil",
        text: "Bargained for Rs 3000 but when they arrived at G-13, they demanded Rs 2000 extra for stairs! Oye total scam.",
        category: "hidden_charges",
        sentiment: "negative",
        date: "4 days ago",
      ),
      MoverReview(
        author: "Zeeshan Ali",
        text: "They just threw the cartons in the pickup. My glass lamp broke because they didn't wrap it. Faltu service.",
        category: "fragile",
        sentiment: "negative",
        date: "2 weeks ago",
      ),
      MoverReview(
        author: "Sajid Shah",
        text: "Arrived 1 hour late and driver was very rude. Avoid if you have expensive items.",
        category: "punctuality",
        sentiment: "negative",
        date: "1 month ago",
      ),
    ],
    agentVerdict: "RISKY CHOICE. This is a fictional mock provider representing standard informal adda loaders. Reviews indicate severe risk of hidden stair surcharges (Rs. 2,000+), zero fragile packing materials, and high delay rate. Selected by baseline apps strictly for lowest price, but rejected by SafeShift AI.",
    hasBlankets: false,
    hasBubbleWrap: false,
    hasCartons: false,
    hasTape: false,
    hasTrolley: false,
    hasStraps: false,
    hasTools: false,
    hasDisassemblyTools: false,
    crewCount: 1,
    applianceExperience: false,
  ),
];
