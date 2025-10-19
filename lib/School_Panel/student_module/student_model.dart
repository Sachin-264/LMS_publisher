class StudentModel {
  final int? recNo;
  final int? schoolRecNo;
  final int? classRecNo;
  final String? studentId;
  final String? admissionNumber;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String gender;
  final String dateOfBirth;
  final String? bloodGroup;
  final String? nationality;
  final String? category;
  final String? academicYear;
  final String? religion;
  final String? mobileNumber;
  final String? alternateContactNumber;
  final String? emailId;
  final String? permanentAddressStreet;
  final String? permanentAddressCity;
  final String? permanentAddressState;
  final String? permanentAddressCountry;
  final String? permanentAddressPIN;
  final String? currentAddressStreet;
  final String? currentAddressCity;
  final String? currentAddressState;
  final String? currentAddressCountry;
  final String? currentAddressPIN;
  final String? fatherName;
  final String? fatherOccupation;
  final String? fatherMobileNumber;
  final String? motherName;
  final String? motherOccupation;
  final String? motherMobileNumber;
  final String? guardianName;
  final String? guardianContactNumber;
  final String? admissionDate;
  final String? admissionClass;
  final String? currentClass;
  final String? sectionDivision;
  final String? rollNumber;
  final String? previousSchoolName;
  final String? previousBoardUniversity;
  final String? mediumOfInstruction;
  final String? aadhaarNumber;
  final String? passportNumber;
  final String? studentPhotoPath;
  final String? transferCertificateNo;
  final String? migrationCertificateNo;
  final String? birthCertificateNo;
  final bool? medicalFitnessCertificate;
  final bool? hostelFacility;
  final bool? transportFacility;
  final String? busRouteNo;
  final bool? scholarshipFinancialAid;
  final String? scholarshipDetails;
  final String? specialNeedsDisability;
  final String? extraCurricularInterests;
  final String? studentUsername;
  final String? studentPassword;
  final String? parentUsername;
  final String? parentPassword;
  final int? subscriptionId;
  final bool? isActive;
  final int? statusId;
  final String? createdDate;
  final String? createdBy;
  final String? modifiedDate;
  final String? modifiedBy;

  // Additional fields from JOIN
  final String? schoolName;
  final String? className;
  final String? sectionName;

  final String? permanentAddress;        // Full street address
  final int? permanentCityId;            // City ID
  final int? permanentDistrictId;        // District ID
  final int? permanentStateId;           // State ID
  final String? permanentCountry;        // Country name
  final String? permanentPIN;            // PIN code

  // ✅ NEW: Hierarchical Current Address
  final String? currentAddress;          // Full street address
  final int? currentCityId;              // City ID
  final int? currentDistrictId;          // District ID
  final int? currentStateId;             // State ID
  final String? currentCountry;          // Country name
  final String? currentPIN;

  StudentModel({
    this.recNo,
    this.schoolRecNo,
    this.classRecNo,
    this.studentId,
    this.admissionNumber,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.academicYear,
    required this.gender,
    required this.dateOfBirth,
    this.bloodGroup,
    this.nationality,
    this.category,
    this.religion,
    this.mobileNumber,
    this.alternateContactNumber,
    this.emailId,
    this.permanentAddressStreet,
    this.permanentAddressCity,
    this.permanentAddressState,
    this.permanentAddressCountry,
    this.permanentAddressPIN,
    this.currentAddressStreet,
    this.currentAddressCity,
    this.currentAddressState,
    this.currentAddressCountry,
    this.currentAddressPIN,
    this.fatherName,
    this.fatherOccupation,
    this.fatherMobileNumber,
    this.motherName,
    this.motherOccupation,
    this.motherMobileNumber,
    this.guardianName,
    this.guardianContactNumber,
    this.admissionDate,
    this.admissionClass,
    this.currentClass,
    this.sectionDivision,
    this.rollNumber,
    this.previousSchoolName,
    this.previousBoardUniversity,
    this.mediumOfInstruction,
    this.aadhaarNumber,
    this.passportNumber,
    this.studentPhotoPath,
    this.transferCertificateNo,
    this.migrationCertificateNo,
    this.birthCertificateNo,
    this.medicalFitnessCertificate,
    this.hostelFacility,
    this.transportFacility,
    this.busRouteNo,
    this.scholarshipFinancialAid,
    this.scholarshipDetails,
    this.specialNeedsDisability,
    this.extraCurricularInterests,
    this.studentUsername,
    this.studentPassword,
    this.parentUsername,
    this.parentPassword,
    this.subscriptionId,
    this.isActive,
    this.statusId,
    this.createdDate,
    this.createdBy,
    this.modifiedDate,
    this.modifiedBy,
    this.schoolName,
    this.className,
    this.sectionName,

    this.permanentAddress,
    this.permanentCityId,
    this.permanentDistrictId,
    this.permanentStateId,
    this.permanentCountry,
    this.permanentPIN,

    this.currentAddress,
    this.currentCityId,
    this.currentDistrictId,
    this.currentStateId,
    this.currentCountry,
    this.currentPIN,
  });

  // Helper function to convert int (0/1) to bool
  static bool? _intToBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return null;
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      recNo: json['RecNo'],
      schoolRecNo: json['School_RecNo'],
      classRecNo: json['ClassRecNo'],
      studentId: json['Student_ID'],
      admissionNumber: json['Admission_Number'],
      firstName: json['First_Name'] ?? '',
      middleName: json['Middle_Name'],
      lastName: json['Last_Name'] ?? '',
      gender: json['Gender'] ?? '',
      dateOfBirth: json['Date_of_Birth'] ?? '',
      bloodGroup: json['Blood_Group'],
      nationality: json['Nationality'],
      category: json['Category'],
      academicYear: json['Academic_Year'],
      religion: json['Religion'],
      mobileNumber: json['Mobile_Number'],
      alternateContactNumber: json['Alternate_Contact_Number'],
      emailId: json['Email_ID'],
      permanentAddressStreet: json['Permanent_Address_Street'],
      permanentAddressCity: json['Permanent_Address_City'],
      permanentAddressState: json['Permanent_Address_State'],
      permanentAddressCountry: json['Permanent_Address_Country'],
      permanentAddressPIN: json['Permanent_Address_PIN'],
      currentAddressStreet: json['Current_Address_Street'],
      currentAddressCity: json['Current_Address_City'],
      currentAddressState: json['Current_Address_State'],
      currentAddressCountry: json['Current_Address_Country'],
      currentAddressPIN: json['Current_Address_PIN'],
      fatherName: json['Father_Name'],
      fatherOccupation: json['Father_Occupation'],
      fatherMobileNumber: json['Father_Mobile_Number'],
      motherName: json['Mother_Name'],
      motherOccupation: json['Mother_Occupation'],
      motherMobileNumber: json['Mother_Mobile_Number'],
      guardianName: json['Guardian_Name'],
      guardianContactNumber: json['Guardian_Contact_Number'],
      admissionDate: json['Admission_Date'],
      admissionClass: json['Admission_Class'],
      currentClass: json['Current_Class'],
      sectionDivision: json['Section_Division'],
      rollNumber: json['Roll_Number'],
      previousSchoolName: json['Previous_School_Name'],
      previousBoardUniversity: json['Previous_Board_University'],
      mediumOfInstruction: json['Medium_of_Instruction'],
      aadhaarNumber: json['Aadhaar_Number'],
      passportNumber: json['Passport_Number'],
      studentPhotoPath: json['Student_Photo_Path'],
      transferCertificateNo: json['Transfer_Certificate_No'],
      migrationCertificateNo: json['Migration_Certificate_No'],
      birthCertificateNo: json['Birth_Certificate_No'],
      medicalFitnessCertificate: _intToBool(json['Medical_Fitness_Certificate']),
      hostelFacility: _intToBool(json['Hostel_Facility']),
      transportFacility: _intToBool(json['Transport_Facility']),
      busRouteNo: json['Bus_Route_No'],
      scholarshipFinancialAid: _intToBool(json['Scholarship_Financial_Aid']),
      scholarshipDetails: json['Scholarship_Details'],
      specialNeedsDisability: json['Special_Needs_Disability'],
      extraCurricularInterests: json['Extra_Curricular_Interests'],
      studentUsername: json['Student_Username'],
      studentPassword: json['Student_Password'],
      parentUsername: json['Parent_Username'],
      parentPassword: json['Parent_Password'],
      subscriptionId: json['Subscription_ID'],
      isActive: _intToBool(json['IsActive']),
      statusId: json['Status_ID'],
      createdDate: json['Created_Date'],
      createdBy: json['Created_By'],
      modifiedDate: json['Modified_Date'],
      modifiedBy: json['Modified_By'],
      schoolName: json['School_Name'],
      className: json['Class_Name'],
      sectionName: json['Section_Name'],

      permanentAddress: json['Permanent_Address']?.toString(),
      permanentCityId: json['Permanent_City_ID'] != null ? int.tryParse(json['Permanent_City_ID'].toString()) : null,
      permanentDistrictId: json['Permanent_District_ID'] != null ? int.tryParse(json['Permanent_District_ID'].toString()) : null,
      permanentStateId: json['Permanent_State_ID'] != null ? int.tryParse(json['Permanent_State_ID'].toString()) : null,
      permanentCountry: json['Permanent_Country']?.toString(),
      permanentPIN: json['Permanent_PIN']?.toString(),

      currentAddress: json['Current_Address']?.toString(),
      currentCityId: json['Current_City_ID'] != null ? int.tryParse(json['Current_City_ID'].toString()) : null,
      currentDistrictId: json['Current_District_ID'] != null ? int.tryParse(json['Current_District_ID'].toString()) : null,
      currentStateId: json['Current_State_ID'] != null ? int.tryParse(json['Current_State_ID'].toString()) : null,
      currentCountry: json['Current_Country']?.toString(),
      currentPIN: json['Current_PIN']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (recNo != null) 'RecNo': recNo,
      if (schoolRecNo != null) 'School_RecNo': schoolRecNo,
      if (classRecNo != null) 'ClassRecNo': classRecNo,
      if (studentId != null) 'Student_ID': studentId,
      if (admissionNumber != null) 'Admission_Number': admissionNumber,
      'First_Name': firstName,
      if (middleName != null) 'Middle_Name': middleName,
      'Last_Name': lastName,
      'Gender': gender,
      'Date_of_Birth': dateOfBirth,
      if (bloodGroup != null) 'Blood_Group': bloodGroup,
      if (nationality != null) 'Nationality': nationality,
      if (category != null) 'Category': category,
      if (religion != null) 'Religion': religion,
      if (academicYear != null) 'Academic_Year': academicYear,
      if (mobileNumber != null) 'Mobile_Number': mobileNumber,
      if (alternateContactNumber != null)
        'Alternate_Contact_Number': alternateContactNumber,
      if (emailId != null) 'Email_ID': emailId,
      if (permanentAddressStreet != null)
        'Permanent_Address_Street': permanentAddressStreet,
      if (permanentAddressCity != null)
        'Permanent_Address_City': permanentAddressCity,
      if (permanentAddressState != null)
        'Permanent_Address_State': permanentAddressState,
      if (permanentAddressCountry != null)
        'Permanent_Address_Country': permanentAddressCountry,
      if (permanentAddressPIN != null)
        'Permanent_Address_PIN': permanentAddressPIN,
      if (currentAddressStreet != null)
        'Current_Address_Street': currentAddressStreet,
      if (currentAddressCity != null) 'Current_Address_City': currentAddressCity,
      if (currentAddressState != null)
        'Current_Address_State': currentAddressState,
      if (currentAddressCountry != null)
        'Current_Address_Country': currentAddressCountry,
      if (currentAddressPIN != null) 'Current_Address_PIN': currentAddressPIN,
      if (fatherName != null) 'Father_Name': fatherName,
      if (fatherOccupation != null) 'Father_Occupation': fatherOccupation,
      if (fatherMobileNumber != null) 'Father_Mobile_Number': fatherMobileNumber,
      if (motherName != null) 'Mother_Name': motherName,
      if (motherOccupation != null) 'Mother_Occupation': motherOccupation,
      if (motherMobileNumber != null) 'Mother_Mobile_Number': motherMobileNumber,
      if (guardianName != null) 'Guardian_Name': guardianName,
      if (guardianContactNumber != null)
        'Guardian_Contact_Number': guardianContactNumber,
      if (admissionDate != null) 'Admission_Date': admissionDate,
      if (admissionClass != null) 'Admission_Class': admissionClass,
      if (currentClass != null) 'Current_Class': currentClass,
      if (sectionDivision != null) 'Section_Division': sectionDivision,
      if (rollNumber != null) 'Roll_Number': rollNumber,
      if (previousSchoolName != null) 'Previous_School_Name': previousSchoolName,
      if (previousBoardUniversity != null)
        'Previous_Board_University': previousBoardUniversity,
      if (mediumOfInstruction != null)
        'Medium_of_Instruction': mediumOfInstruction,
      if (aadhaarNumber != null) 'Aadhaar_Number': aadhaarNumber,
      if (passportNumber != null) 'Passport_Number': passportNumber,
      if (studentPhotoPath != null) 'Student_Photo_Path': studentPhotoPath,
      if (transferCertificateNo != null)
        'Transfer_Certificate_No': transferCertificateNo,
      if (migrationCertificateNo != null)
        'Migration_Certificate_No': migrationCertificateNo,
      if (birthCertificateNo != null) 'Birth_Certificate_No': birthCertificateNo,
      if (medicalFitnessCertificate != null)
        'Medical_Fitness_Certificate': medicalFitnessCertificate,
      if (hostelFacility != null) 'Hostel_Facility': hostelFacility,
      if (transportFacility != null) 'Transport_Facility': transportFacility,
      if (busRouteNo != null) 'Bus_Route_No': busRouteNo,
      if (scholarshipFinancialAid != null)
        'Scholarship_Financial_Aid': scholarshipFinancialAid,
      if (scholarshipDetails != null) 'Scholarship_Details': scholarshipDetails,
      if (specialNeedsDisability != null)
        'Special_Needs_Disability': specialNeedsDisability,
      if (extraCurricularInterests != null)
        'Extra_Curricular_Interests': extraCurricularInterests,
      if (studentUsername != null) 'Student_Username': studentUsername,
      if (studentPassword != null) 'Student_Password': studentPassword,
      if (parentUsername != null) 'Parent_Username': parentUsername,
      if (parentPassword != null) 'Parent_Password': parentPassword,
      if (subscriptionId != null) 'Subscription_ID': subscriptionId,
      if (isActive != null) 'IsActive': isActive,
      if (statusId != null) 'Status_ID': statusId,
      if (createdBy != null) 'Operation_By': createdBy,
    };
  }

  String get fullName => '$firstName ${middleName ?? ''} $lastName'.trim();
}
