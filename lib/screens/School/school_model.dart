// lib/models/school_model.dart

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

// --- NEW: SchoolStatusModel to replace the enum ---
// This model directly maps to your API response for statuses.
class SchoolStatusModel extends Equatable {
  final String id;
  final String name;

  const SchoolStatusModel({required this.id, required this.name});

  factory SchoolStatusModel.fromJson(Map<String, dynamic> json) {
    return SchoolStatusModel(
      id: json['Status_ID']?.toString() ?? '',
      name: json['Status_Name']?.toString() ?? 'Unknown',
    );
  }

  // A constant for a default/unknown status to avoid nulls
  static const unknown = SchoolStatusModel(id: '-1', name: 'Unknown');

  @override
  List<Object?> get props => [id, name];
}


// --- Keep your existing helper classes like FeeStructure, StateModel, etc. ---
class FeeStructure {
  final String id;
  final String name;

  FeeStructure({required this.id, required this.name});
}

class StateModel {
  final String id;
  final String name;
  StateModel({required this.id, required this.name});
}

class DistrictModel {
  final String id;
  final String name;
  DistrictModel({required this.id, required this.name});
}

class CityModel {
  final String id;
  final String name;
  CityModel({required this.id, required this.name});
}

// --- Your existing SubscriptionPlan class is perfectly fine ---
// *** NO CHANGES NEEDED for SubscriptionPlan, DurationOption, PlanFeature ***
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final String planType;
  final String currency;
  final double price;
  final String billingCycle;
  final double discountPercent;
  final int trialPeriodDays;
  final int usersAllowed;
  final int devicesAllowed;
  final String contentAccessType;
  final int concurrentSessions;
  final bool isRecordedLectures;
  final bool isAssignmentsTests;
  final bool isDownloadableResources;
  final bool isDiscussionForum;
  final String supportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isAutoRenewal;
  final bool isActive;
  final double taxPercent;
  final String? paymentGatewayRef;
  final String createdBy;
  final DateTime? createdDate;
  final String? modifiedBy;
  final DateTime? modifiedDate;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.planType,
    required this.currency,
    required this.price,
    required this.billingCycle,
    required this.discountPercent,
    required this.trialPeriodDays,
    required this.usersAllowed,
    required this.devicesAllowed,
    required this.contentAccessType,
    required this.concurrentSessions,
    required this.isRecordedLectures,
    required this.isAssignmentsTests,
    required this.isDownloadableResources,
    required this.isDiscussionForum,
    required this.supportType,
    this.startDate,
    this.endDate,
    required this.isAutoRenewal,
    required this.isActive,
    required this.taxPercent,
    this.paymentGatewayRef,
    required this.createdBy,
    this.createdDate,
    this.modifiedBy,
    this.modifiedDate,
  });

  // Helper method to parse dates from your API format
  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr.toLowerCase() == 'null') return null;
    try {
      // Handle format like "2025-09-30 10:44:14.730"
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Fallback for other formats
        return DateFormat("yyyy-MM-dd").parse(dateStr);
      } catch (_) {
        print('Could not parse subscription date: "$dateStr"');
        return null;
      }
    }
  }

  // Factory constructor to match your exact API response
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['Subscription_ID']?.toString() ?? '',
      name: json['Subscription_Name']?.toString() ?? '',
      description: json['Description']?.toString() ?? '',
      planType: json['Plan_Type']?.toString() ?? '',
      currency: json['Currency']?.toString() ?? 'USD',
      price: double.tryParse(json['Price']?.toString() ?? '0') ?? 0.0,
      billingCycle: json['Billing_Cycle']?.toString() ?? '',
      discountPercent: double.tryParse(json['Discount_Percent']?.toString() ?? '0') ?? 0.0,
      trialPeriodDays: int.tryParse(json['Trial_Period_Days']?.toString() ?? '0') ?? 0,
      usersAllowed: int.tryParse(json['Users_Allowed']?.toString() ?? '0') ?? 0,
      devicesAllowed: int.tryParse(json['Devices_Allowed']?.toString() ?? '0') ?? 0,
      contentAccessType: json['Content_Access_Type']?.toString() ?? '',
      concurrentSessions: int.tryParse(json['Concurrent_Sessions']?.toString() ?? '0') ?? 0,
      isRecordedLectures: json['Is_Recorded_Lectures'] == '1',
      isAssignmentsTests: json['Is_Assignments_Tests'] == '1',
      isDownloadableResources: json['Is_Downloadable_Resources'] == '1',
      isDiscussionForum: json['Is_Discussion_Forum'] == '1',
      supportType: json['Support_Type']?.toString() ?? '',
      startDate: _parseDate(json['Start_Date']?.toString()),
      endDate: _parseDate(json['End_Date']?.toString()),
      isAutoRenewal: json['Is_Auto_Renewal'] == '1',
      isActive: json['Is_Status'] == '1',
      taxPercent: double.tryParse(json['Tax_Percent']?.toString() ?? '0') ?? 0.0,
      paymentGatewayRef: json['Payment_Gateway_Ref']?.toString(),
      createdBy: json['Created_By']?.toString() ?? '',
      createdDate: _parseDate(json['Created_Date']?.toString()),
      modifiedBy: json['Modified_By']?.toString(),
      modifiedDate: _parseDate(json['Modified_Date']?.toString()),
    );
  }

  // --- All other helper methods in SubscriptionPlan remain the same ---
  List<DurationOption> get availableDurations {
    switch (planType.toLowerCase()) {
      case 'weekly':
        return [
          const DurationOption(weeks: 1, label: '1 Week'),
          const DurationOption(weeks: 2, label: '2 Weeks'),
          const DurationOption(weeks: 4, label: '4 Weeks'),
          const DurationOption(weeks: 8, label: '8 Weeks'),
          const DurationOption(weeks: 12, label: '12 Weeks'),
        ];
      case 'monthly':
        return [
          const DurationOption(months: 1, label: '1 Month'),
          const DurationOption(months: 3, label: '3 Months'),
          const DurationOption(months: 6, label: '6 Months'),
          const DurationOption(months: 12, label: '1 Year'),
        ];
      case 'yearly':
        return [
          const DurationOption(months: 12, label: '1 Year'),
          const DurationOption(months: 24, label: '2 Years'),
          const DurationOption(months: 36, label: '3 Years'),
        ];
      default:
      // For any other plan types, provide flexible options
        return [
          const DurationOption(weeks: 1, label: '1 Week'),
          const DurationOption(months: 1, label: '1 Month'),
          const DurationOption(months: 6, label: '6 Months'),
          const DurationOption(months: 12, label: '1 Year'),
        ];
    }
  }

  // Calculate final price with discount and tax
  double get finalPrice {
    final discountAmount = (price * discountPercent) / 100;
    final discountedPrice = price - discountAmount;
    final taxAmount = (discountedPrice * taxPercent) / 100;
    return discountedPrice + taxAmount;
  }

  // Get display price with currency
  String get displayPrice {
    if (price == 0) {
      return 'Free';
    }
    return '$currency ${price.toStringAsFixed(2)}';
  }

  // Get display final price with currency
  String get displayFinalPrice {
    if (finalPrice == 0) {
      return 'Free';
    }
    return '$currency ${finalPrice.toStringAsFixed(2)}';
  }

  // Check if plan has discount
  bool get hasDiscount => discountPercent > 0;

  // Check if plan has tax
  bool get hasTax => taxPercent > 0;

  // Get plan features as list
  List<PlanFeature> get features {
    return [
      PlanFeature(
        icon: 'profile_2user',
        label: 'Users Allowed',
        value: '$usersAllowed',
        isEnabled: true,
      ),
      PlanFeature(
        icon: 'mobile',
        label: 'Devices Allowed',
        value: '$devicesAllowed',
        isEnabled: true,
      ),
      PlanFeature(
        icon: 'play_circle',
        label: 'Recorded Lectures',
        value: isRecordedLectures ? 'Yes' : 'No',
        isEnabled: isRecordedLectures,
      ),
      PlanFeature(
        icon: 'task_square',
        label: 'Assignments & Tests',
        value: isAssignmentsTests ? 'Yes' : 'No',
        isEnabled: isAssignmentsTests,
      ),
      PlanFeature(
        icon: 'document_download',
        label: 'Downloadable Resources',
        value: isDownloadableResources ? 'Yes' : 'No',
        isEnabled: isDownloadableResources,
      ),
      PlanFeature(
        icon: 'messages_2',
        label: 'Discussion Forum',
        value: isDiscussionForum ? 'Yes' : 'No',
        isEnabled: isDiscussionForum,
      ),
      PlanFeature(
        icon: 'headphone',
        label: 'Support Type',
        value: supportType,
        isEnabled: true,
      ),
    ];
  }

  @override
  String toString() => 'SubscriptionPlan(id: $id, name: $name, planType: $planType, price: $displayPrice)';
}



// Helper class for duration options
class DurationOption {
  final int? weeks;
  final int? months;
  final String label;

  const DurationOption({this.weeks, this.months, required this.label});

  Duration get duration {
    if (weeks != null) {
      return Duration(days: weeks! * 7);
    } else if (months != null) {
      return Duration(days: months! * 30); // Approximate
    }
    return const Duration(days: 30);
  }

  String get value => weeks != null ? '${weeks}w' : '${months}m';

  int get multiplier => weeks ?? months ?? 1;

  @override
  String toString() => label;
}

// Helper class for plan features
class PlanFeature {
  final String icon;
  final String label;
  final String value;
  final bool isEnabled;

  const PlanFeature({
    required this.icon,
    required this.label,
    required this.value,
    required this.isEnabled,
  });
}


// --- REMOVED: The SchoolStatus enum is no longer needed ---
// enum SchoolStatus { Active, Expired, Trial, Suspended, NotAvailable }

// *** UPDATED School class to handle the new API structure ***
class School {
  final String id;
  String name;
  String? code;
  String? subscription; // This will now hold the subscription name
  SchoolStatusModel status; // MODIFIED: Changed from enum to model

  String? recNo;
  String? shortName;
  String? schoolType;
  String? medium;
  String? board;
  String? affiliationNo;
  String? establishmentDate;
  String? address1;
  String? address2;
  String? country;
  String? stateId;
  String? districtId;
  String? cityId;
  String? pincode;
  String? phone;
  String? mobile;
  String? email;
  String? website;
  String? principalName;
  String? principalContact;
  String? contactPerson;
  String? chairmanName;
  String? managementType;
  String? branchCount;
  String? parentOrganization;
  String? classesOffered;
  String? sectionsPerClass;
  String? studentCapacity;
  String? currentEnrollment;
  String? teacherStrength;
  bool? isHostel;
  bool? isTransport;
  bool? isLibrary;
  bool? isComputerLab;
  bool? isPlayground;
  bool? isAuditorium;
  String? pan;
  String? gst;
  String? bankAccountDetails;
  String? feeStructureRef;
  String? scholarshipsGrants;
  String? logoPath;
  DateTime? createdDate;
  String? createdBy;
  DateTime? modifiedDate;
  String? modifiedBy;
  bool? isActive;

  // Subscription-related fields
  String? subSchoolId;
  DateTime? purchaseDate;
  DateTime? startDate;
  DateTime? endDate;
  String? paymentRefId;
  bool? isAutoRenewal;

  // Now holds the full subscription plan details
  final SubscriptionPlan? subscriptionPlan;

  School({
    required this.id,
    required this.name,
    this.code,
    this.subscription,
    required this.status, // MODIFIED
    this.recNo,
    this.shortName,
    this.schoolType,
    this.medium,
    this.board,
    this.affiliationNo,
    this.establishmentDate,
    this.address1,
    this.address2,
    this.country,
    this.stateId,
    this.districtId,
    this.cityId,
    this.pincode,
    this.phone,
    this.mobile,
    this.email,
    this.website,
    this.principalName,
    this.principalContact,
    this.contactPerson,
    this.chairmanName,
    this.managementType,
    this.branchCount,
    this.parentOrganization,
    this.classesOffered,
    this.sectionsPerClass,
    this.studentCapacity,
    this.currentEnrollment,
    this.teacherStrength,
    this.isHostel,
    this.isTransport,
    this.isLibrary,
    this.isComputerLab,
    this.isPlayground,
    this.isAuditorium,
    this.pan,
    this.gst,
    this.bankAccountDetails,
    this.feeStructureRef,
    this.scholarshipsGrants,
    this.logoPath,
    this.createdDate,
    this.createdBy,
    this.modifiedDate,
    this.modifiedBy,
    this.isActive,
    this.subSchoolId,
    this.purchaseDate,
    this.startDate,
    this.endDate,
    this.paymentRefId,
    this.isAutoRenewal,
    this.subscriptionPlan, // Added subscription plan
  });

  String get validity {
    if (startDate != null && endDate != null) {
      final startFormatted = DateFormat.yMMMd().format(startDate!);
      final endFormatted = DateFormat.yMMMd().format(endDate!);
      return '$startFormatted to $endFormatted';
    }
    return 'N/A';
  }

  // --- REMOVED: _parseStatus method is no longer needed ---

  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr.toLowerCase() == 'null') return null;
    try {
      // API format "2025-10-04 16:09:18.667"
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Fallback for "MMM d yyyy h:mma"
        final sanitizedStr = dateStr.replaceAll(RegExp(r'\s+'), ' ');
        return DateFormat("MMM d yyyy h:mma").parse(sanitizedStr);
      } catch (_) {
        print('Could not parse date: "$dateStr"');
        return null;
      }
    }
  }

  // --- MODIFIED: fromListJson now creates a SchoolStatusModel ---
  factory School.fromListJson(Map<String, dynamic> json) {
    DateTime? tempStartDate;
    DateTime? tempEndDate;

    final validityStr = json['Validity'] as String?;

    if (validityStr != null && validityStr.toLowerCase() != 'n/a' && validityStr.contains(' to ')) {
      final parts = validityStr.split(' to ');
      if (parts.length == 2) {
        tempStartDate = _parseDate(parts[0]);
        tempEndDate = _parseDate(parts[1]);
      }
    }

    return School(
      id: json['School_ID']?.toString() ?? '0',
      name: json['School Name'] ?? 'Unknown School',
      code: json['School_Code'],
      subscription: json['Subscription'],
      // Create a SchoolStatusModel directly from the list API's response keys
      status: SchoolStatusModel(
        id: json['Status_ID']?.toString() ?? '-1',
        name: json['Status'] ?? 'Unknown',
      ),
      startDate: tempStartDate,
      endDate: tempEndDate,
      principalName: json['Principal_Name'],
      email: json['Email'],
      mobile: json['Mobile_No'],
      logoPath: json['Logo_Path'],
    );
  }

  // *** MODIFIED: fromDetailJson factory constructor also creates a SchoolStatusModel ***
  factory School.fromDetailJson(Map<String, dynamic> json) {
    final schoolData = json['School_Master_Data'] as Map<String, dynamic>? ?? {};
    final schoolSubList = json['School_Subscription'] as List<dynamic>? ?? [];
    final subMasterList = json['Subscription_Master'] as List<dynamic>? ?? [];

    final schoolSubData = schoolSubList.isNotEmpty ? Map<String, dynamic>.from(schoolSubList.first) : <String, dynamic>{};
    final subMasterData = subMasterList.isNotEmpty ? Map<String, dynamic>.from(subMasterList.first) : <String, dynamic>{};

    final subscriptionPlan = subMasterList.isNotEmpty ? SubscriptionPlan.fromJson(subMasterData) : null;

    return School(
      // --- Data from School_Master_Data ---
      id: schoolData['School_ID']?.toString() ?? '0',
      name: schoolData['School_Name'] ?? 'N/A',
      code: schoolData['School_Code'],
      recNo: schoolData['RecNo']?.toString(),
      shortName: schoolData['School_Short_Name'],
      schoolType: schoolData['SchoolType_ID']?.toString(),
      medium: schoolData['Medium_ID']?.toString(),
      board: schoolData['BoardAffiliation_ID']?.toString(),
      affiliationNo: schoolData['Affiliation_No']?.toString(),
      establishmentDate: schoolData['Date_of_Establishment'],
      address1: schoolData['Address_Line1'],
      address2: schoolData['Address_Line2'],
      country: schoolData['Country'],
      stateId: schoolData['State_ID']?.toString(),
      districtId: schoolData['District_ID']?.toString(),
      cityId: schoolData['City_ID']?.toString(),
      pincode: schoolData['Pin_Code'],
      phone: schoolData['Phone_No'],
      mobile: schoolData['Mobile_No'],
      email: schoolData['Email'],
      website: schoolData['Website'],
      principalName: schoolData['Principal_Name'],
      principalContact: schoolData['Principal_Contact'],
      contactPerson: schoolData['Principal_Name'], // Assuming same as principal
      chairmanName: schoolData['Chairman_Name'],
      managementType: schoolData['Management_ID']?.toString(),
      branchCount: schoolData['Branch_Count']?.toString(),
      parentOrganization: schoolData['Parent_Organization'],
      classesOffered: schoolData['Classes_Offered'],
      sectionsPerClass: schoolData['Sections_Per_Class']?.toString(),
      studentCapacity: schoolData['Student_Capacity']?.toString(),
      currentEnrollment: schoolData['Current_Enrollment']?.toString(),
      teacherStrength: schoolData['Teacher_Strength']?.toString(),
      isHostel: schoolData['IsHostel'] == '1',
      isTransport: schoolData['IsTransport'] == '1',
      isLibrary: schoolData['IsLibrary'] == '1',
      isComputerLab: schoolData['IsComputer_Lab'] == '1',
      isPlayground: schoolData['IsPlayground'] == '1',
      isAuditorium: schoolData['IsAuditorium'] == '1',
      pan: schoolData['PAN_Number'],
      gst: schoolData['GST_Number'],
      bankAccountDetails: schoolData['Bank_Account_Details'],
      feeStructureRef: schoolData['Fee_Structure_Ref']?.toString(),
      scholarshipsGrants: schoolData['Scholarships_Grants'],
      logoPath: schoolData['Logo_Path'],
      createdDate: _parseDate(schoolData['Created_Date']),
      createdBy: schoolData['Created_By'],
      modifiedDate: _parseDate(schoolData['Modified_Date']),
      modifiedBy: schoolData['Modified_By'],
      isActive: schoolData['Status_ID'] == '1',

      // --- Data from School_Subscription ---
      // Create a SchoolStatusModel from the subscription data
      status: SchoolStatusModel(
        id: schoolSubData['Status_ID']?.toString() ?? '-1',
        name: schoolSubData['Status_Name'] ?? schoolSubData['Status'] ?? 'Unknown',
      ),
      subSchoolId: schoolSubData['School_ID']?.toString(), // This seems redundant, but mapping anyway
      purchaseDate: _parseDate(schoolSubData['Purchase_Date']),
      startDate: _parseDate(schoolSubData['Start_Date']),
      endDate: _parseDate(schoolSubData['End_Date']),
      paymentRefId: schoolSubData['Payment_Ref_ID'],
      isAutoRenewal: schoolSubData['Is_Auto_Renewal'] == '1',

      // --- Data from Subscription_Master ---
      subscription: subMasterData['Subscription_Name'],
      subscriptionPlan: subscriptionPlan,
    );
  }
}