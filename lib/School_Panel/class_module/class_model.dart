// class_model.dart

/// Model for Master Class options (from Class_Master for dropdown)
class MasterClassOption {
  final int classID;
  final String className;
  final String? classDescription;
  final int? displayOrder;

  MasterClassOption({
    required this.classID,
    required this.className,
    this.classDescription,
    this.displayOrder,
  });

  factory MasterClassOption.fromJson(Map<String, dynamic> json) {
    return MasterClassOption(
      classID: int.tryParse(json['Class_ID']?.toString() ?? '0') ?? 0,
      className: json['Class_Name']?.toString() ?? '',
      classDescription: json['ClassDescription']?.toString(),
      displayOrder: json['DisplayOrder'] != null ? int.tryParse(json['DisplayOrder'].toString()) : null,
    );
  }
}

/// Model for School Class data
class ClassModel {
  final int? classRecNo;
  final int schoolID;
  final int classID; // Changed from String to int
  final String className;
  final String classCode;
  final String sectionName;
  final String? roomNumber;
  final int? maxStudentCapacity;
  final String academicYear;
  final String? classStartDate;
  final String? classEndDate;
  final int? classTeacherRecNo;
  final String? classTeacherName;
  final int statusID;
  final bool isActive;
  final String? createdBy;
  final String? modifiedBy;

  ClassModel({
    this.classRecNo,
    required this.schoolID,
    required this.classID,
    required this.className,
    required this.classCode,
    required this.sectionName,
    this.roomNumber,
    this.maxStudentCapacity,
    required this.academicYear,
    this.classStartDate,
    this.classEndDate,
    this.classTeacherRecNo,
    this.classTeacherName,
    this.statusID = 1,
    this.isActive = true,
    this.createdBy,
    this.modifiedBy,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      classRecNo: json['ClassRecNo'] != null ? int.tryParse(json['ClassRecNo'].toString()) : null,
      schoolID: int.tryParse(json['School_RecNo']?.toString() ?? '0') ?? 0,
      classID: int.tryParse(json['Class_ID']?.toString() ?? '0') ?? 0,
      className: json['Class_Name']?.toString() ?? '',
      classCode: json['Class_Code']?.toString() ?? '',
      sectionName: json['Section_Name']?.toString() ?? '',
      roomNumber: json['Room_Number']?.toString(),
      maxStudentCapacity: json['Max_Student_Capacity'] != null
          ? int.tryParse(json['Max_Student_Capacity'].toString())
          : null,
      academicYear: json['Academic_Year']?.toString() ?? '2025-26',
      classStartDate: json['Class_Start_Date']?.toString(),
      classEndDate: json['Class_End_Date']?.toString(),
      classTeacherRecNo: json['Class_Teacher_RecNo'] != null
          ? int.tryParse(json['Class_Teacher_RecNo'].toString())
          : null,
      classTeacherName: json['Class_Teacher_Name']?.toString(),
      statusID: json['Status_ID'] != null ? int.tryParse(json['Status_ID'].toString()) ?? 1 : 1,
      isActive: json['IsActive'] == 1 || json['IsActive'] == '1' || json['IsActive'] == true,
      createdBy: json['Created_By']?.toString(),
      modifiedBy: json['Modified_By']?.toString(),
    );
  }

  Map<String, dynamic> toAddJson(String action, String operationBy) {
    return {
      'action': action,
      'School_ID': schoolID,
      'Class_ID': classID,
      'Class_Name': className,
      'Class_Code': classCode,
      'Section_Name': sectionName,
      'Room_Number': roomNumber,
      'Max_Student_Capacity': maxStudentCapacity,
      'Academic_Year': academicYear,
      'Class_Start_Date': classStartDate,
      'Class_End_Date': classEndDate,
      'Class_Teacher_RecNo': classTeacherRecNo,
      'Status_ID': statusID,
      'IsActive': isActive ? 1 : 0,
      'Created_By': operationBy,
    };
  }

  Map<String, dynamic> toUpdateJson(String action, String operationBy) {
    return {
      'action': action,
      'ClassRecNo': classRecNo,
      'School_ID': schoolID,
      'Class_ID': classID,
      'Class_Name': className,
      'Class_Code': classCode,
      'Section_Name': sectionName,
      'Room_Number': roomNumber,
      'Max_Student_Capacity': maxStudentCapacity,
      'Academic_Year': academicYear,
      'Class_Start_Date': classStartDate,
      'Class_End_Date': classEndDate,
      'Class_Teacher_RecNo': classTeacherRecNo,
      'Status_ID': statusID,
      'IsActive': isActive ? 1 : 0,
      'Modified_By': operationBy,
    };
  }

  String get fullName => '$className - $sectionName';
}

/// Model for Subject Allotment (Subject linked to Class) WITH Teacher Info
class ClassSubjectModel {
  final int subjectID;
  final String subjectName;
  final String? subjectCode;
  final String? displayName;

  // Teacher Allotment Info (NEW)
  final int? allotmentRecNo;
  final int? teacherRecNo;
  final String? teacherName;
  final String? teacherContact;
  final String? teacherDesignation;
  final String? allotmentStartDate;
  final String? allotmentEndDate;
  final int? allotmentStatus;

  ClassSubjectModel({
    required this.subjectID,
    required this.subjectName,
    this.subjectCode,
    this.displayName,
    this.allotmentRecNo,
    this.teacherRecNo,
    this.teacherName,
    this.teacherContact,
    this.teacherDesignation,
    this.allotmentStartDate,
    this.allotmentEndDate,
    this.allotmentStatus,
  });

  factory ClassSubjectModel.fromJson(Map<String, dynamic> json) {
    return ClassSubjectModel(
      subjectID: int.tryParse(json['SubjectID']?.toString() ?? '0') ?? 0,
      subjectName: json['SubjectName']?.toString() ?? '',
      subjectCode: json['SubjectCode']?.toString(),
      displayName: json['DisplayName']?.toString(),

      // Teacher Allotment Info
      allotmentRecNo: json['AllotmentRecNo'] != null
          ? int.tryParse(json['AllotmentRecNo'].toString())
          : null,
      teacherRecNo: json['TeacherRecNo'] != null
          ? int.tryParse(json['TeacherRecNo'].toString())
          : null,
      teacherName: json['TeacherName']?.toString(),
      teacherContact: json['TeacherContact']?.toString(),
      teacherDesignation: json['TeacherDesignation']?.toString(),
      allotmentStartDate: json['AllotmentStartDate']?.toString(),
      allotmentEndDate: json['AllotmentEndDate']?.toString(),
      allotmentStatus: json['AllotmentStatus'] != null
          ? int.tryParse(json['AllotmentStatus'].toString())
          : null,
    );
  }

  // Helper getter
  bool get hasTeacher => teacherRecNo != null && teacherName != null;
}


/// Model for Teacher Allotment to a Subject in a Class
class SubjectTeacherAllotmentModel {
  final int allotmentRecNo;
  final int classRecNo;
  final int subjectID;
  final String subjectName;
  final int teacherRecNo;
  final String teacherName;
  final String startDate;
  final String endDate;
  final int isActive;

  SubjectTeacherAllotmentModel({
    required this.allotmentRecNo,
    required this.classRecNo,
    required this.subjectID,
    required this.subjectName,
    required this.teacherRecNo,
    required this.teacherName,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory SubjectTeacherAllotmentModel.fromJson(Map<String, dynamic> json) {
    return SubjectTeacherAllotmentModel(
      allotmentRecNo: json['AllotmentRecNo'] != null ? int.tryParse(json['AllotmentRecNo'].toString()) ?? 0 : 0,
      classRecNo: int.tryParse(json['ClassRecNo']?.toString() ?? '0') ?? 0,
      subjectID: int.tryParse(json['SubjectID']?.toString() ?? '0') ?? 0,
      subjectName: json['SubjectName']?.toString() ?? '',
      teacherRecNo: int.tryParse(json['TeacherRecNo']?.toString() ?? '0') ?? 0,
      teacherName: json['TeacherName']?.toString() ?? '',
      startDate: json['Start_Date']?.toString() ?? '',
      endDate: json['End_Date']?.toString() ?? '',
      isActive: int.tryParse(json['Status_ID']?.toString() ?? '1') ?? 1,
    );
  }
}

/// Model for available Teachers (simplified)
class TeacherOptionModel {
  final int recNo;
  final String name;

  TeacherOptionModel({
    required this.recNo,
    required this.name,
  });

  factory TeacherOptionModel.fromJson(Map<String, dynamic> json) {
    return TeacherOptionModel(
      recNo: int.tryParse(json['TeacherRecNo']?.toString() ?? '0') ?? 0,
      name: json['FullName']?.toString() ?? json['TeacherName']?.toString() ?? '',
    );
  }

  String get fullName => name;
}

/// Model for available Subjects (simplified)
class SubjectOptionModel {
  final int subjectID;
  final String subjectName;
  final String? subjectCode;

  SubjectOptionModel({
    required this.subjectID,
    required this.subjectName,
    this.subjectCode,
  });

  factory SubjectOptionModel.fromJson(Map<String, dynamic> json) {
    return SubjectOptionModel(
      subjectID: int.tryParse(json['SubjectID']?.toString() ?? '0') ?? 0,
      subjectName: json['SubjectName']?.toString() ?? '',
      subjectCode: json['SubjectCode']?.toString(),
    );
  }
}