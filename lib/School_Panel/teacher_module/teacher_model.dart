class TeacherModel {
  final int? recNo;
  final int? schoolRecNo;
  final String? teacherCode;
  final String? employeeCode;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String gender;
  final String dateOfBirth;
  final String? bloodGroup;
  final String? nationality;
  final String? category;
  final String? religion;
  final String? mobileNumber;
  final String? alternateContactNumber;
  final String? personalEmail;
  final String? institutionalEmail;
  final String? permanentAddress;
  final String? currentAddress;
  final int? permanentCityId;
  final int? permanentDistrictId;
  final int? permanentStateId;
  final String? permanentCountry;  // Changed to String as per your ALTER
  final String? permanentPin;
  final int? currentCityId;
  final int? currentDistrictId;
  final int? currentStateId;
  final String? currentCountry;  // Changed to String as per your ALTER
  final String? currentPin;
  final String? dateOfJoining;
  final String? designation;
  final String? department;
  final String? subjectsTaught;
  final String? qualification;
  final int? experienceYears; // ✅ Keep as int
  final String? employmentType;
  final String? employeeStatus;
  final String? aadhaarNumber;
  final String? panNumber;
  final String? passportNumber;
  final String? photograph;
  final String? certificateFile;
  final String? registrationNo;
  final int? salaryId;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? bankName;
  final String? pfNumber;
  final String? esiNumber;
  final String? uanNumber;
  final String? maritalStatus;
  final String? emergencyContact;
  final String? specialSkills;
  final String? achievements;
  final String? extraResponsibilities;
  final String? userName;
  final String? password;
  final bool? isActive;
  final String? createdDate;
  final String? createdBy;
  final String? modifiedDate;
  final String? modifiedBy;
  final String? schoolName;

  TeacherModel({
    this.recNo,
    this.schoolRecNo,
    this.teacherCode,
    this.employeeCode,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    this.bloodGroup,
    this.nationality,
    this.category,
    this.religion,
    this.mobileNumber,
    this.alternateContactNumber,
    this.personalEmail,
    this.institutionalEmail,
    this.permanentAddress,
    this.currentAddress,
    this.permanentCityId,
    this.permanentDistrictId,
    this.permanentStateId,
    this.permanentCountry,
    this.permanentPin,
    this.currentCityId,
    this.currentDistrictId,
    this.currentStateId,
    this.currentCountry,
    this.currentPin,
    this.dateOfJoining,
    this.designation,
    this.department,
    this.subjectsTaught,
    this.qualification,
    this.experienceYears,
    this.employmentType,
    this.employeeStatus,
    this.aadhaarNumber,
    this.panNumber,
    this.passportNumber,
    this.photograph,
    this.certificateFile,
    this.registrationNo,
    this.salaryId,
    this.bankAccountNumber,
    this.ifscCode,
    this.bankName,
    this.pfNumber,
    this.esiNumber,
    this.uanNumber,
    this.maritalStatus,
    this.emergencyContact,
    this.specialSkills,
    this.achievements,
    this.extraResponsibilities,
    this.userName,
    this.password,
    this.isActive,
    this.createdDate,
    this.createdBy,
    this.modifiedDate,
    this.modifiedBy,
    this.schoolName,
  });

  // Helper function to convert int (0/1) to bool
  static bool? _intToBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return null;
  }

  // ✅ Helper function to convert dynamic to int
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed?.toInt();
    }
    return null;
  }

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      recNo: json['RecNo'],
      schoolRecNo: json['SchoolRecNo'],
      teacherCode: json['TeacherCode'],
      employeeCode: json['EmployeeCode'],
      firstName: json['FirstName'] ?? '',
      middleName: json['MiddleName'],
      lastName: json['LastName'] ?? '',
      gender: json['Gender'] ?? '',
      dateOfBirth: json['DateOfBirth'] ?? '',
      bloodGroup: json['BloodGroup'],
      nationality: json['Nationality'],
      category: json['Category'],
      religion: json['Religion'],
      mobileNumber: json['MobileNumber'],
      alternateContactNumber: json['AlternateContactNumber'],
      personalEmail: json['PersonalEmail'],
      institutionalEmail: json['InstitutionalEmail'],
      permanentAddress: json['PermanentAddress'],
      currentAddress: json['CurrentAddress'],
      permanentCityId: _toInt(json['Permanent_City_ID']),
      permanentDistrictId: _toInt(json['Permanent_District_ID']),
      permanentStateId: _toInt(json['Permanent_State_ID']),
      permanentCountry: json['Permanent_Country'],
      permanentPin: json['Permanent_PIN'],
      currentCityId: _toInt(json['Current_City_ID']),
      currentDistrictId: _toInt(json['Current_District_ID']),
      currentStateId: _toInt(json['Current_State_ID']),
      currentCountry: json['Current_Country'],
      currentPin: json['Current_PIN'],
      dateOfJoining: json['DateOfJoining'],
      designation: json['Designation'],
      department: json['Department'],
      subjectsTaught: json['SubjectsTaught'],
      qualification: json['Qualification'],
      experienceYears: _toInt(json['ExperienceYears']), // ✅ Convert to int
      employmentType: json['EmploymentType'],
      employeeStatus: json['EmployeeStatus'],
      aadhaarNumber: json['AadhaarNumber'],
      panNumber: json['PANNumber'],
      passportNumber: json['PassportNumber'],
      photograph: json['Photograph'],
      certificateFile: json['CertificateFile'],
      registrationNo: json['RegistrationNo'],
      salaryId: _toInt(json['SalaryID']), // ✅ Convert to int
      bankAccountNumber: json['BankAccountNumber'],
      ifscCode: json['IFSCCode'],
      bankName: json['BankName'],
      pfNumber: json['PFNumber'],
      esiNumber: json['ESINumber'],
      uanNumber: json['UANNumber'],
      maritalStatus: json['MaritalStatus'],
      emergencyContact: json['EmergencyContact'],
      specialSkills: json['SpecialSkills'],
      achievements: json['Achievements'],
      extraResponsibilities: json['ExtraResponsibilities'],
      userName: json['UserName'],
      password: json['Password'],
      isActive: _intToBool(json['IsActive']),
      createdDate: json['CreatedDate'],
      createdBy: json['CreatedBy'],
      modifiedDate: json['ModifiedDate'],
      modifiedBy: json['ModifiedBy'],
      schoolName: json['SchoolName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (recNo != null) 'RecNo': recNo,
      if (schoolRecNo != null) 'SchoolRecNo': schoolRecNo,
      if (teacherCode != null) 'TeacherCode': teacherCode,
      if (employeeCode != null) 'EmployeeCode': employeeCode,
      'FirstName': firstName,
      if (middleName != null) 'MiddleName': middleName,
      'LastName': lastName,
      'Gender': gender,
      'DateOfBirth': dateOfBirth,
      if (bloodGroup != null) 'BloodGroup': bloodGroup,
      if (nationality != null) 'Nationality': nationality,
      if (category != null) 'Category': category,
      if (religion != null) 'Religion': religion,
      if (mobileNumber != null) 'MobileNumber': mobileNumber,
      if (alternateContactNumber != null) 'AlternateContactNumber': alternateContactNumber,
      if (personalEmail != null) 'PersonalEmail': personalEmail,
      if (institutionalEmail != null) 'InstitutionalEmail': institutionalEmail,
      if (permanentAddress != null) 'PermanentAddress': permanentAddress,
      if (currentAddress != null) 'CurrentAddress': currentAddress,
      if (permanentCityId != null) 'Permanent_City_ID': permanentCityId,
      if (permanentDistrictId != null) 'Permanent_District_ID': permanentDistrictId,
      if (permanentStateId != null) 'Permanent_State_ID': permanentStateId,
      if (permanentCountry != null) 'Permanent_Country': permanentCountry,
      if (permanentPin != null) 'Permanent_PIN': permanentPin,
      if (currentCityId != null) 'Current_City_ID': currentCityId,
      if (currentDistrictId != null) 'Current_District_ID': currentDistrictId,
      if (currentStateId != null) 'Current_State_ID': currentStateId,
      if (currentCountry != null) 'Current_Country': currentCountry,
      if (currentPin != null) 'Current_PIN': currentPin,
      if (dateOfJoining != null) 'DateOfJoining': dateOfJoining,
      if (designation != null) 'Designation': designation,
      if (department != null) 'Department': department,
      if (subjectsTaught != null) 'SubjectsTaught': subjectsTaught,
      if (qualification != null) 'Qualification': qualification,
      if (experienceYears != null) 'ExperienceYears': experienceYears,
      if (employmentType != null) 'EmploymentType': employmentType,
      if (employeeStatus != null) 'EmployeeStatus': employeeStatus,
      if (aadhaarNumber != null) 'AadhaarNumber': aadhaarNumber,
      if (panNumber != null) 'PANNumber': panNumber,
      if (passportNumber != null) 'PassportNumber': passportNumber,
      if (photograph != null) 'Photograph': photograph,
      if (certificateFile != null) 'CertificateFile': certificateFile,
      if (registrationNo != null) 'RegistrationNo': registrationNo,
      if (salaryId != null) 'SalaryID': salaryId,
      if (bankAccountNumber != null) 'BankAccountNumber': bankAccountNumber,
      if (ifscCode != null) 'IFSCCode': ifscCode,
      if (bankName != null) 'BankName': bankName,
      if (pfNumber != null) 'PFNumber': pfNumber,
      if (esiNumber != null) 'ESINumber': esiNumber,
      if (uanNumber != null) 'UANNumber': uanNumber,
      if (maritalStatus != null) 'MaritalStatus': maritalStatus,
      if (emergencyContact != null) 'EmergencyContact': emergencyContact,
      if (specialSkills != null) 'SpecialSkills': specialSkills,
      if (achievements != null) 'Achievements': achievements,
      if (extraResponsibilities != null) 'ExtraResponsibilities': extraResponsibilities,
      if (userName != null) 'UserName': userName,
      if (password != null) 'Password': password,
      if (isActive != null) 'IsActive': isActive,
      if (createdBy != null) 'ModifiedBy': createdBy,
    };
  }

  String get fullName => '$firstName ${middleName ?? ''} $lastName'.trim();
}
