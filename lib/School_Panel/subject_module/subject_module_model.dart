// lib/School_Panel/subject_module/subject_module_model.dart

// ============================================================================
// HELPER FUNCTION FOR SAFE INTEGER PARSING
// ============================================================================
int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

// ============================================================================
// AVAILABLE CLASS MODEL (From Publisher)
// ============================================================================
class AvailableClassModel {
  final int classID;
  final String className;
  final String classDescription;
  final int displayOrder;
  final int isActive;
  final String? createdDate;
  final String? modifiedDate;
  final int totalSubjects;
  final int totalChapters;
  final int isAddedBySchool;

  AvailableClassModel({
    required this.classID,
    required this.className,
    required this.classDescription,
    required this.displayOrder,
    required this.isActive,
    this.createdDate,
    this.modifiedDate,
    required this.totalSubjects,
    required this.totalChapters,
    required this.isAddedBySchool,
  });

  factory AvailableClassModel.fromJson(Map<String, dynamic> json) {
    return AvailableClassModel(
      classID: _parseInt(json['ClassID']),
      className: json['ClassName']?.toString() ?? '',
      classDescription: json['ClassDescription']?.toString() ?? '',
      displayOrder: _parseInt(json['DisplayOrder']),
      isActive: _parseInt(json['IsActive']),
      createdDate: json['CreatedDate'],
      modifiedDate: json['ModifiedDate'],
      totalSubjects: _parseInt(json['TotalSubjects']),
      totalChapters: _parseInt(json['TotalChapters']),
      isAddedBySchool: _parseInt(json['IsAddedBySchool']),
    );
  }
}

// ============================================================================
// AVAILABLE SUBJECT MODEL (From Publisher)
// ============================================================================
class AvailableSubjectModel {
  final int subjectID;
  final String subjectName;
  final String subjectCode;
  final String subjectDescription;
  final int classID;
  final int isActive;
  final String? createdDate;
  final String? modifiedDate;
  final String className;
  final String classDescription;
  final int classDisplayOrder;
  final int totalChapters;
  final int totalMaterials;
  final int isAddedBySchool;

  AvailableSubjectModel({
    required this.subjectID,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectDescription,
    required this.classID,
    required this.isActive,
    this.createdDate,
    this.modifiedDate,
    required this.className,
    required this.classDescription,
    required this.classDisplayOrder,
    required this.totalChapters,
    required this.totalMaterials,
    required this.isAddedBySchool,
  });

  factory AvailableSubjectModel.fromJson(Map<String, dynamic> json) {
    return AvailableSubjectModel(
      subjectID: _parseInt(json['SubjectID']),
      subjectName: json['SubjectName']?.toString() ?? '',
      subjectCode: json['SubjectCode']?.toString() ?? '',
      subjectDescription: json['SubjectDescription']?.toString() ?? '',
      classID: _parseInt(json['ClassID']),
      isActive: _parseInt(json['IsActive']),
      createdDate: json['CreatedDate'],
      modifiedDate: json['ModifiedDate'],
      className: json['ClassName']?.toString() ?? '',
      classDescription: json['ClassDescription']?.toString() ?? '',
      classDisplayOrder: _parseInt(json['ClassDisplayOrder']),
      totalChapters: _parseInt(json['TotalChapters']),
      totalMaterials: _parseInt(json['TotalMaterials']),
      isAddedBySchool: _parseInt(json['IsAddedBySchool']),
    );
  }
}

// ============================================================================
// AVAILABLE CHAPTER MODEL (From Publisher)
// ============================================================================
class AvailableChapterModel {
  final int chapterID;
  final String chapterName;
  final String chapterCode;
  final String chapterDescription;
  final int chapterOrder;
  final int subjectID;
  final int isActive;
  final String? chapterCreatedDate;
  final String? chapterModifiedDate;
  final String subjectName;
  final String subjectCode;
  final String subjectDescription;
  final int classID;
  final String className;
  final String classDescription;
  final int classDisplayOrder;
  final int? materialRecNo;
  final String? materialID;
  final String? videoLink;
  final String? worksheetPath;
  final String? extraQuestionsPath;
  final String? solvedQuestionsPath;
  final String? revisionNotesPath;
  final String? lessonPlansPath;
  final String? teachingAidsPath;
  final String? assessmentToolsPath;
  final String? homeworkToolsPath;
  final String? practiceZonePath;
  final String? learningPathPath;
  final String? uploadedOn;
  final int hasMaterial;
  final int isAddedBySchool;

  AvailableChapterModel({
    required this.chapterID,
    required this.chapterName,
    required this.chapterCode,
    required this.chapterDescription,
    required this.chapterOrder,
    required this.subjectID,
    required this.isActive,
    this.chapterCreatedDate,
    this.chapterModifiedDate,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectDescription,
    required this.classID,
    required this.className,
    required this.classDescription,
    required this.classDisplayOrder,
    this.materialRecNo,
    this.materialID,
    this.videoLink,
    this.worksheetPath,
    this.extraQuestionsPath,
    this.solvedQuestionsPath,
    this.revisionNotesPath,
    this.lessonPlansPath,
    this.teachingAidsPath,
    this.assessmentToolsPath,
    this.homeworkToolsPath,
    this.practiceZonePath,
    this.learningPathPath,
    this.uploadedOn,
    required this.hasMaterial,
    required this.isAddedBySchool,
  });

  factory AvailableChapterModel.fromJson(Map<String, dynamic> json) {
    return AvailableChapterModel(
      chapterID: _parseInt(json['ChapterID']),
      chapterName: json['ChapterName']?.toString() ?? '',
      chapterCode: json['ChapterCode']?.toString() ?? '',
      chapterDescription: json['ChapterDescription']?.toString() ?? '',
      chapterOrder: _parseInt(json['ChapterOrder']),
      subjectID: _parseInt(json['SubjectID']),
      isActive: _parseInt(json['IsActive']),
      chapterCreatedDate: json['ChapterCreatedDate'],
      chapterModifiedDate: json['ChapterModifiedDate'],
      subjectName: json['SubjectName']?.toString() ?? '',
      subjectCode: json['SubjectCode']?.toString() ?? '',
      subjectDescription: json['SubjectDescription']?.toString() ?? '',
      classID: _parseInt(json['ClassID']),
      className: json['ClassName']?.toString() ?? '',
      classDescription: json['ClassDescription']?.toString() ?? '',
      classDisplayOrder: _parseInt(json['ClassDisplayOrder']),
      materialRecNo: _parseInt(json['Material_RecNo']),
      materialID: json['Material_ID'],
      videoLink: json['Video_Link'],
      worksheetPath: json['Worksheet_Path'],
      extraQuestionsPath: json['Extra_Questions_Path'],
      solvedQuestionsPath: json['Solved_Questions_Path'],
      revisionNotesPath: json['Revision_Notes_Path'],
      lessonPlansPath: json['Lesson_Plans_Path'],
      teachingAidsPath: json['Teaching_Aids_Path'],
      assessmentToolsPath: json['Assessment_Tools_Path'],
      homeworkToolsPath: json['Homework_Tools_Path'],
      practiceZonePath: json['Practice_Zone_Path'],
      learningPathPath: json['Learning_Path_Path'],
      uploadedOn: json['Uploaded_On'],
      hasMaterial: _parseInt(json['HasMaterial']),
      isAddedBySchool: _parseInt(json['IsAddedBySchool']),
    );
  }
}

// ============================================================================
// SCHOOL CLASS MASTER MODEL (School's own classes from School_Class_Master)
// ============================================================================
class SchoolClassMasterModel {
  final int classRecNo;
  final int schoolRecNo;
  final int classID;
  final String className;
  final String sectionName;
  final String? classCode;
  final String? classTeacherName;
  final String academicYear;
  final int? maxStudentCapacity;
  final int? currentStudentCount;
  final int isActive;
  final String? masterClassName;
  final String? classDescription;

  SchoolClassMasterModel({
    required this.classRecNo,
    required this.schoolRecNo,
    required this.classID,
    required this.className,
    required this.sectionName,
    this.classCode,
    this.classTeacherName,
    required this.academicYear,
    this.maxStudentCapacity,
    this.currentStudentCount,
    required this.isActive,
    this.masterClassName,
    this.classDescription,
  });

  factory SchoolClassMasterModel.fromJson(Map<String, dynamic> json) {
    return SchoolClassMasterModel(
      classRecNo: _parseInt(json['ClassRecNo']),
      schoolRecNo: _parseInt(json['School_RecNo']),
      classID: _parseInt(json['Class_ID']),
      className: json['Class_Name']?.toString() ?? '',
      sectionName: json['Section_Name']?.toString() ?? '',
      classCode: json['Class_Code'],
      classTeacherName: json['Class_Teacher_Name'],
      academicYear: json['Academic_Year']?.toString() ?? '',
      maxStudentCapacity: _parseInt(json['Max_Student_Capacity']),
      currentStudentCount: _parseInt(json['Current_Student_Count']),
      isActive: _parseInt(json['IsActive']),
      masterClassName: json['Master_ClassName'],
      classDescription: json['ClassDescription'],
    );
  }
}

// ============================================================================
// TEACHER MODEL
// ============================================================================
class TeacherModel {
  final int teacherRecNo;
  final int schoolRecNo;
  final String teacherCode;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String fullName;
  final String? designation;
  final String? department;
  final String? mobileNumber;
  final String? personalEmail;
  final int? experienceYears;
  final String? employmentType;
  final String? employeeStatus;
  final int isActive;

  TeacherModel({
    required this.teacherRecNo,
    required this.schoolRecNo,
    required this.teacherCode,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.fullName,
    this.designation,
    this.department,
    this.mobileNumber,
    this.personalEmail,
    this.experienceYears,
    this.employmentType,
    this.employeeStatus,
    required this.isActive,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      teacherRecNo: _parseInt(json['TeacherRecNo']),
      schoolRecNo: _parseInt(json['SchoolRecNo']),
      teacherCode: json['TeacherCode']?.toString() ?? '',
      firstName: json['FirstName']?.toString() ?? '',
      middleName: json['MiddleName'],
      lastName: json['LastName']?.toString() ?? '',
      fullName: json['FullName']?.toString() ?? '',
      designation: json['Designation'],
      department: json['Department'],
      mobileNumber: json['MobileNumber'],
      personalEmail: json['PersonalEmail'],
      experienceYears: _parseInt(json['ExperienceYears']),
      employmentType: json['EmploymentType'],
      employeeStatus: json['EmployeeStatus'],
      isActive: _parseInt(json['IsActive']),
    );
  }
}

// ============================================================================
// SCHOOL ADDED CLASS MODEL (Classes that school has added content for)
// ============================================================================
class SchoolClassModel {
  final int classID;
  final String className;
  final String classDescription;
  final int displayOrder;
  final int classIsActive;
  final int addedSubjects;
  final int addedChapters;
  final String? firstAddedDate;
  final String? lastModifiedDate;
  final String academicYear;

  SchoolClassModel({
    required this.classID,
    required this.className,
    required this.classDescription,
    required this.displayOrder,
    required this.classIsActive,
    required this.addedSubjects,
    required this.addedChapters,
    this.firstAddedDate,
    this.lastModifiedDate,
    required this.academicYear,
  });

  factory SchoolClassModel.fromJson(Map<String, dynamic> json) {
    return SchoolClassModel(
      classID: _parseInt(json['ClassID']),
      className: json['ClassName']?.toString() ?? '',
      classDescription: json['ClassDescription']?.toString() ?? '',
      displayOrder: _parseInt(json['DisplayOrder']),
      classIsActive: _parseInt(json['ClassIsActive']),
      addedSubjects: _parseInt(json['AddedSubjects']),
      addedChapters: _parseInt(json['AddedChapters']),
      firstAddedDate: json['FirstAddedDate'],
      lastModifiedDate: json['LastModifiedDate'],
      academicYear: json['Academic_Year']?.toString() ?? '',
    );
  }
}

// ============================================================================
// ALLOTMENT MODEL (Subject-level allotment)
// ============================================================================
class AllotmentModel {
  final int classRecNo;
  final String className;
  final String sectionName;
  final int teacherRecNo;
  final String teacherName;
  final String teacherCode;
  final int allotmentRecNo;
  final int statusID;

  AllotmentModel({
    required this.classRecNo,
    required this.className,
    required this.sectionName,
    required this.teacherRecNo,
    required this.teacherName,
    required this.teacherCode,
    required this.allotmentRecNo,
    required this.statusID,
  });

  factory AllotmentModel.fromJson(Map<String, dynamic> json) {
    return AllotmentModel(
      classRecNo: _parseInt(json['ClassRecNo']),
      className: json['ClassName']?.toString() ?? '',
      sectionName: json['Section_Name']?.toString() ?? '',
      teacherRecNo: _parseInt(json['TeacherRecNo']),
      teacherName: json['TeacherName']?.toString() ?? '',
      teacherCode: json['TeacherCode']?.toString() ?? '',
      allotmentRecNo: _parseInt(json['AllotmentRecNo']),
      statusID: _parseInt(json['Status_ID'], defaultValue: 1),
    );
  }
}

// ============================================================================
// SCHOOL SUBJECT MODEL (Subjects that school has added with allotments)
// ============================================================================
class SchoolSubjectModel {
  final int subjectID;
  final String subjectName;
  final String subjectCode;
  final String subjectDescription;
  final int classID;
  final int subjectIsActive;
  final String className;
  final String classDescription;
  final int addedChapters;
  final String? earliestStartDate;
  final String? latestEndDate;
  final String? firstAddedDate;
  final String? lastModifiedDate;
  final String? customSubjectName;
  final List<AllotmentModel> allotments;

  SchoolSubjectModel({
    required this.subjectID,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectDescription,
    required this.classID,
    required this.subjectIsActive,
    required this.className,
    required this.classDescription,
    required this.addedChapters,
    this.earliestStartDate,
    this.latestEndDate,
    this.firstAddedDate,
    this.lastModifiedDate,
    this.customSubjectName,
    required this.allotments,
  });

  factory SchoolSubjectModel.fromJson(Map<String, dynamic> json) {
    List<AllotmentModel> allotmentsList = [];
    if (json['Allotments'] != null) {
      if (json['Allotments'] is List) {
        allotmentsList = (json['Allotments'] as List)
            .map((item) => AllotmentModel.fromJson(item))
            .toList();
      }
    }

    return SchoolSubjectModel(
      subjectID: _parseInt(json['SubjectID']),
      subjectName: json['SubjectName']?.toString() ?? '',
      subjectCode: json['SubjectCode']?.toString() ?? '',
      subjectDescription: json['SubjectDescription']?.toString() ?? '',
      classID: _parseInt(json['ClassID']),
      subjectIsActive: _parseInt(json['SubjectIsActive']),
      className: json['ClassName']?.toString() ?? '',
      classDescription: json['ClassDescription']?.toString() ?? '',
      addedChapters: _parseInt(json['AddedChapters']),
      earliestStartDate: json['EarliestStartDate'],
      latestEndDate: json['LatestEndDate'],
      firstAddedDate: json['FirstAddedDate'],
      lastModifiedDate: json['LastModifiedDate'],
      customSubjectName: json['Custom_Subject_Name'],
      allotments: allotmentsList,
    );
  }
}

// ============================================================================
// SCHOOL CHAPTER MODEL (Chapters that school has added)
// ============================================================================
class SchoolChapterModel {
  final int recNo;
  final int chapterID;
  final String chapterName;
  final String chapterCode;
  final String chapterDescription;
  final int chapterOrder;
  final int subjectID;
  final int isActiveForSchool;
  final String subjectName;
  final String subjectCode;
  final int classID;
  final String className;
  final String? customSubjectName;
  final String? customChapterName;
  final String? firstAddedDate;
  final String? lastModifiedDate;
  final int? materialRecNo;
  final String? videoLink;
  final String? worksheetPath;
  final String? revisionNotesPath;
  final int hasMaterial;
  final List<AllotmentModel> allotments;

  SchoolChapterModel({
    required this.recNo,
    required this.chapterID,
    required this.chapterName,
    required this.chapterCode,
    required this.chapterDescription,
    required this.chapterOrder,
    required this.subjectID,
    required this.isActiveForSchool,
    required this.subjectName,
    required this.subjectCode,
    required this.classID,
    required this.className,
    this.customSubjectName,
    this.customChapterName,
    this.firstAddedDate,
    this.lastModifiedDate,
    this.materialRecNo,
    this.videoLink,
    this.worksheetPath,
    this.revisionNotesPath,
    required this.hasMaterial,
    required this.allotments,
  });

  factory SchoolChapterModel.fromJson(Map<String, dynamic> json) {
    List<AllotmentModel> allotmentsList = [];
    if (json['Allotments'] != null) {
      if (json['Allotments'] is List) {
        allotmentsList = (json['Allotments'] as List)
            .map((item) => AllotmentModel.fromJson(item))
            .toList();
      }
    }

    return SchoolChapterModel(
      recNo: _parseInt(json['RecNo']),
      chapterID: _parseInt(json['ChapterID']),
      chapterName: json['ChapterName']?.toString() ?? '',
      chapterCode: json['ChapterCode']?.toString() ?? '',
      chapterDescription: json['ChapterDescription']?.toString() ?? '',
      chapterOrder: _parseInt(json['ChapterOrder']),
      subjectID: _parseInt(json['SubjectID']),
      isActiveForSchool: _parseInt(json['ChapterIsActive']) != 0
          ? _parseInt(json['ChapterIsActive'])
          : _parseInt(json['Is_Active_For_School']),
      subjectName: json['SubjectName']?.toString() ?? '',
      subjectCode: json['SubjectCode']?.toString() ?? '',
      classID: _parseInt(json['ClassID']),
      className: json['ClassName']?.toString() ?? '',
      customSubjectName: json['Custom_Subject_Name'],
      customChapterName: json['Custom_Chapter_Name'],
      firstAddedDate: json['FirstAddedDate'],
      lastModifiedDate: json['LastModifiedDate'],
      materialRecNo: _parseInt(json['Material_RecNo']),
      videoLink: json['Video_Link'],
      worksheetPath: json['Worksheet_Path'],
      revisionNotesPath: json['Revision_Notes_Path'],
      hasMaterial: _parseInt(json['HasMaterial']),
      allotments: allotmentsList,
    );
  }
}
