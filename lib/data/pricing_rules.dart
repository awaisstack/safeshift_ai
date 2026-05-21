class PricingRules {
  static const double baseMoveRate = 5000.0;
  static const double perCrewMemberRate = 1500.0;
  static const double suzukiTruckRate = 3000.0;
  static const double shahzorTruckRate = 5000.0;
  static const double largeTruckRate = 8000.0;
  
  static const double noLiftSurcharge = 1000.0; // Per floor typically, or flat
  static const double fragileItemSurcharge = 500.0; // Per item
  static const double heavyApplianceSurcharge = 800.0; // Per item
  static const double standardPackingMaterialRate = 200.0; // Per carton/item estimated
  
  static const double weekendDemandMultiplier = 1.2;
  static const double urgentMultiplier = 1.3;
  static const double protectionFee = 700.0;
}
