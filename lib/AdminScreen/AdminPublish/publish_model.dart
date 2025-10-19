import 'package:flutter/foundation.dart';

// Helper function to safely parse a value to an integer.
// It can handle int, double, and String types.
int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

// Model for the Key Performance Indicator (KPI) cards on the dashboard.
class AdminKPIs {
  final int subjectCount;
  final int materialCount;
  final int schoolCount;
  final int publisherCount;

  AdminKPIs({
    required this.subjectCount,
    required this.materialCount,
    required this.schoolCount,
    required this.publisherCount,
  });

  factory AdminKPIs.fromJson(Map<String, dynamic> json) {
    return AdminKPIs(
      subjectCount: _parseInt(json['SubjectCount']),
      materialCount: _parseInt(json['MaterialCount']),
      schoolCount: _parseInt(json['SchoolCount']),
      publisherCount: _parseInt(json['PublisherCount']),
    );
  }
}

// Basic model for displaying a publisher in a list.
// Contains only the essential information needed for the main view.
class Publisher {
  final int recNo;
  final int? pubCode;  // NEW - mapped from PubCode
  final String? adminCode;  // NEW - mapped from AdminCode
  final String publisherName;
  final String publisherType;
  final int isActive;
  final String createdDate;

  Publisher({
    required this.recNo,
    required this.pubCode,
    required this.adminCode,
    required this.publisherName,
    required this.publisherType,
    required this.isActive,
    required this.createdDate,
  });

  factory Publisher.fromJson(Map<String, dynamic> json) {
    return Publisher(
      recNo: _parseInt(json['RecNo']),
      pubCode: json['PubCode'] != null ? _parseInt(json['PubCode']) : null,  // NEW
      adminCode: json['AdminCode'],  // NEW
      publisherName: json['PublisherName'] ?? 'N/A',
      publisherType: json['PublisherType'] ?? '',
      isActive: _parseInt(json['IsActive']),
      createdDate: json['CreatedDate'] ?? '',
    );
  }


}


// Update the PublisherDetail model to handle Logo field
class PublisherDetail {
  final int recNo;
  final int? pubCode;
  final String? adminCode;  // NEW
  final String publisherName;
  final String publisherType;
  final int yearOfEstablishment;
  final String contactPersonName;
  final String contactPersonDesignation;
  final String emailID;
  final String phoneNumber;
  final String alternatePhoneNumber;
  final String faxNumber;
  final String addressLine1;
  final String addressLine2;
  final int? cityID;
  final int? stateID;
  final int? districtID;
  final String country;
  final String pinZipCode;
  final String website;
  final String gstNumber;
  final String panNumber;
  final String bankAccountDetails;
  final int? paymentID;
  final String distributionType;
  final String areasCovered;
  final String languagesPublished;
  final int numberOfTitles;
  final String? logoFileName; // Add this field
  final int isActive;
  final String? userID;
  final String password;
  final int? userGroupCode;


  PublisherDetail({
    required this.recNo,
    required this.pubCode,
    required this.adminCode,
    required this.publisherName,
    required this.publisherType,
    required this.yearOfEstablishment,
    required this.contactPersonName,
    required this.contactPersonDesignation,
    required this.emailID,
    required this.phoneNumber,
    required this.alternatePhoneNumber,
    required this.faxNumber,
    required this.addressLine1,
    required this.addressLine2,
    this.cityID,
    this.stateID,
    this.districtID,
    required this.country,
    required this.pinZipCode,
    required this.website,
    required this.gstNumber,
    required this.panNumber,
    required this.bankAccountDetails,
    this.paymentID,
    required this.distributionType,
    required this.areasCovered,
    required this.languagesPublished,
    required this.numberOfTitles,
    this.logoFileName, // Add this
    required this.isActive,
    required this.userID,
    required this.password,
    required this.userGroupCode
  });

  factory PublisherDetail.fromJson(Map<String, dynamic> json) {
    return PublisherDetail(
      recNo: _parseInt(json['RecNo']),
      pubCode: json['PubCode'] != null ? _parseInt(json['PubCode']) : null,
      adminCode: json['AdminCode'],
      publisherName: json['PublisherName'] ?? '',
      publisherType: json['PublisherType'] ?? '',
      yearOfEstablishment: _parseInt(json['YearOfEstablishment']),
      contactPersonName: json['ContactPersonName'] ?? '',
      contactPersonDesignation: json['ContactPersonDesignation'] ?? '',
      emailID: json['EmailID'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? '',
      alternatePhoneNumber: json['AlternatePhoneNumber'] ?? '',
      faxNumber: json['FaxNumber'] ?? '',
      addressLine1: json['AddressLine1'] ?? '',
      addressLine2: json['AddressLine2'] ?? '',
      cityID: json['CityID'] != null ? _parseInt(json['CityID']) : null,
      stateID: json['StateID'] != null ? _parseInt(json['StateID']) : null,
      districtID: json['DistrictID'] != null ? _parseInt(json['DistrictID']) : null,
      country: json['Country'] ?? '',
      pinZipCode: json['PinZipCode'] ?? '',
      website: json['Website'] ?? '',
      gstNumber: json['GSTNumber'] ?? '',
      panNumber: json['PANNumber'] ?? '',
      bankAccountDetails: json['BankAccountDetails'] ?? '',
      paymentID: json['PaymentID'] != null ? _parseInt(json['PaymentID']) : null,
      distributionType: json['DistributionType'] ?? '',
      areasCovered: json['AreasCovered'] ?? '',
      languagesPublished: json['LanguagesPublished'] ?? '',
      numberOfTitles: _parseInt(json['NumberOfTitles']),
      logoFileName: json['Logo'], // Map Logo field to logoFileName
      isActive: _parseInt(json['IsActive'], defaultValue: 1),
      userID: json['UserID'],
      userGroupCode: json['UserGroupCode'] != null ? _parseInt(json['UserGroupCode']) : null,
      password: json['Password'] ?? '',
    );
  }
}

// Helper function
