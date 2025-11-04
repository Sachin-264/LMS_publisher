import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================================
// EVENTS
// ============================================================================

abstract class SchoolPanelEvent extends Equatable {
  const SchoolPanelEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends SchoolPanelEvent {
  final int schoolRecNo;
  final String academicYear;

  const LoadDashboardData({
    required this.schoolRecNo,
    required this.academicYear,
  });

  @override
  List<Object?> get props => [schoolRecNo, academicYear];
}

class RefreshDashboard extends SchoolPanelEvent {
  final int schoolRecNo;
  final String academicYear;

  const RefreshDashboard({
    required this.schoolRecNo,
    required this.academicYear,
  });

  @override
  List<Object?> get props => [schoolRecNo, academicYear];
}

// ============================================================================
// STATES
// ============================================================================

abstract class SchoolPanelState extends Equatable {
  const SchoolPanelState();

  @override
  List<Object?> get props => [];
}

class SchoolPanelInitial extends SchoolPanelState {}

class SchoolPanelLoading extends SchoolPanelState {}

class DashboardLoaded extends SchoolPanelState {
  final DashboardData data;

  const DashboardLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class SchoolPanelError extends SchoolPanelState {
  final String message;

  const SchoolPanelError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// DATA MODELS
// ============================================================================

class DashboardData {
  final KpiSummary kpiSummary;
  final List<EnrollmentData> enrollmentTrend;
  final List<ClassDistribution> classDistribution;
  final List<SubjectData> subjectDistribution;
  final List<TeacherWorkload> teacherWorkload;
  final List<GenderData> genderDistribution;
  final List<ContentAvailability> contentAvailability;
  final List<ActivityItem> recentActivities;
  final List<AllocationMatrix> allocationMatrix;
  final StudyMaterialStats studyMaterialStats;
  final List<YearComparison> yearComparison;

  DashboardData({
    required this.kpiSummary,
    required this.enrollmentTrend,
    required this.classDistribution,
    required this.subjectDistribution,
    required this.teacherWorkload,
    required this.genderDistribution,
    required this.contentAvailability,
    required this.recentActivities,
    required this.allocationMatrix,
    required this.studyMaterialStats,
    required this.yearComparison,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    try {
      final data = json['data'];

      return DashboardData(
        kpiSummary: KpiSummary.fromJson(data['kpiSummary'] ?? {}),
        enrollmentTrend: (data['enrollmentTrend'] as List? ?? [])
            .map((e) => EnrollmentData.fromJson(e))
            .toList(),
        classDistribution: (data['classDistribution'] as List? ?? [])
            .map((e) => ClassDistribution.fromJson(e))
            .toList(),
        subjectDistribution: (data['subjectDistribution'] as List? ?? [])
            .map((e) => SubjectData.fromJson(e))
            .toList(),
        teacherWorkload: (data['teacherWorkload'] as List? ?? [])
            .map((e) => TeacherWorkload.fromJson(e))
            .toList(),
        genderDistribution: (data['genderDistribution'] as List? ?? [])
            .map((e) => GenderData.fromJson(e))
            .toList(),
        contentAvailability: (data['contentAvailability'] as List? ?? [])
            .map((e) => ContentAvailability.fromJson(e))
            .toList(),
        recentActivities: (data['recentActivities'] as List? ?? [])
            .map((e) => ActivityItem.fromJson(e))
            .toList(),
        allocationMatrix: (data['allocationMatrix'] as List? ?? [])
            .map((e) => AllocationMatrix.fromJson(e))
            .toList(),
        studyMaterialStats: StudyMaterialStats.fromJson(
          data['studyMaterialStats'] ?? {},
        ),
        yearComparison: (data['yearComparison'] as List? ?? [])
            .map((e) => YearComparison.fromJson(e))
            .toList(),
      );
    } catch (e) {
      throw Exception('Failed to parse dashboard data: $e');
    }
  }
}

class KpiSummary {
  final int totalStudents;
  final int totalTeachers;
  final int totalSubjects;
  final int totalClasses;
  final int totalAllotments;
  final double teacherStudentRatio;
  final int maleStudents;
  final int femaleStudents;
  final int totalChapters;

  KpiSummary({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalSubjects,
    required this.totalClasses,
    required this.totalAllotments,
    required this.teacherStudentRatio,
    required this.maleStudents,
    required this.femaleStudents,
    required this.totalChapters,
  });

  factory KpiSummary.fromJson(Map<String, dynamic> json) {
    return KpiSummary(
      totalStudents: json['TotalStudents'] ?? 0,
      totalTeachers: json['TotalTeachers'] ?? 0,
      totalSubjects: json['TotalSubjects'] ?? 0,
      totalClasses: json['TotalClasses'] ?? 0,
      totalAllotments: json['TotalAllotments'] ?? 0,
      teacherStudentRatio: double.tryParse(json['TeacherStudentRatio']?.toString() ?? '0') ?? 0.0,
      maleStudents: json['MaleStudents'] ?? 0,
      femaleStudents: json['FemaleStudents'] ?? 0,
      totalChapters: json['TotalChapters'] ?? 0,
    );
  }
}

class EnrollmentData {
  final String month;
  final int monthNumber;
  final int yearNumber;
  final int count;

  EnrollmentData({
    required this.month,
    required this.monthNumber,
    required this.yearNumber,
    required this.count,
  });

  factory EnrollmentData.fromJson(Map<String, dynamic> json) {
    return EnrollmentData(
      month: json['MonthYear'] ?? '',
      monthNumber: json['MonthNumber'] ?? 0,
      yearNumber: json['YearNumber'] ?? 0,
      count: json['StudentCount'] ?? 0,
    );
  }
}

class ClassDistribution {
  final String className;
  final int studentCount;
  final int? classRecNo;

  ClassDistribution({
    required this.className,
    required this.studentCount,
    this.classRecNo,
  });

  factory ClassDistribution.fromJson(Map<String, dynamic> json) {
    return ClassDistribution(
      className: json['ClassName'] ?? 'Unknown',
      studentCount: json['StudentCount'] ?? 0,
      classRecNo: json['ClassRecNo'],
    );
  }
}

class SubjectData {
  final String subject;
  final String? subjectCode;
  final String? displayName;
  final int teacherCount;
  final int classCount;
  final int totalAllotments;
  final int? totalChapters;

  SubjectData({
    required this.subject,
    this.subjectCode,
    this.displayName,
    required this.teacherCount,
    required this.classCount,
    required this.totalAllotments,
    this.totalChapters,
  });

  factory SubjectData.fromJson(Map<String, dynamic> json) {
    return SubjectData(
      subject: json['SubjectName'] ?? 'Unknown',
      subjectCode: json['SubjectCode'],
      displayName: json['DisplayName'],
      teacherCount: json['TeacherCount'] ?? 0,
      classCount: json['ClassCount'] ?? 0,
      totalAllotments: json['TotalAllotments'] ?? 0,
      totalChapters: json['TotalChapters'],
    );
  }
}

class TeacherWorkload {
  final int teacherRecNo;
  final String teacherName;
  final String? employeeCode;
  final String? designation;
  final String? department;
  final int subjectCount;
  final int classCount;
  final int totalAllotments;

  TeacherWorkload({
    required this.teacherRecNo,
    required this.teacherName,
    this.employeeCode,
    this.designation,
    this.department,
    required this.subjectCount,
    required this.classCount,
    required this.totalAllotments,
  });

  factory TeacherWorkload.fromJson(Map<String, dynamic> json) {
    return TeacherWorkload(
      teacherRecNo: json['TeacherRecNo'] ?? 0,
      teacherName: json['TeacherName'] ?? 'Unknown',
      employeeCode: json['EmployeeCode'],
      designation: json['Designation'],
      department: json['Department'],
      subjectCount: json['SubjectCount'] ?? 0,
      classCount: json['ClassCount'] ?? 0,
      totalAllotments: json['TotalAllotments'] ?? 0,
    );
  }
}

class GenderData {
  final String gender;
  final int count;
  final double percentage;

  GenderData({
    required this.gender,
    required this.count,
    required this.percentage,
  });

  factory GenderData.fromJson(Map<String, dynamic> json) {
    return GenderData(
      gender: json['Gender'] ?? 'Unknown',
      count: json['Count'] ?? 0,
      percentage: double.tryParse(json['Percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ContentAvailability {
  final String className;
  final String? sectionName;
  final int availableSubjects;
  final int availableChapters;

  ContentAvailability({
    required this.className,
    this.sectionName,
    required this.availableSubjects,
    required this.availableChapters,
  });

  factory ContentAvailability.fromJson(Map<String, dynamic> json) {
    return ContentAvailability(
      className: json['ClassName'] ?? 'Unknown',
      sectionName: json['Section_Name'],
      availableSubjects: json['AvailableSubjects'] ?? 0,
      availableChapters: json['AvailableChapters'] ?? 0,
    );
  }
}

class ActivityItem {
  final String type;
  final String title;
  final String description;
  final String time;
  final String createdBy;

  ActivityItem({
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    required this.createdBy,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      type: json['ActivityType'] ?? 'info',
      title: json['ActivityTitle'] ?? 'Activity',
      description: json['ActivityDetails'] ?? '',
      time: json['ActivityDate'] ?? '',
      createdBy: json['CreatedBy'] ?? '',
    );
  }
}

class AllocationMatrix {
  final int allotmentRecNo;
  final String subjectName;
  final String? subjectCode;
  final String? displaySubjectName;
  final String teacherName;
  final String? employeeCode;
  final String className;
  final int classRecNo;
  final String? startDate;
  final String? endDate;
  final int statusId;
  final String academicYear;

  AllocationMatrix({
    required this.allotmentRecNo,
    required this.subjectName,
    this.subjectCode,
    this.displaySubjectName,
    required this.teacherName,
    this.employeeCode,
    required this.className,
    required this.classRecNo,
    this.startDate,
    this.endDate,
    required this.statusId,
    required this.academicYear,
  });

  factory AllocationMatrix.fromJson(Map<String, dynamic> json) {
    return AllocationMatrix(
      allotmentRecNo: json['AllotmentRecNo'] ?? 0,
      subjectName: json['SubjectName'] ?? '',
      subjectCode: json['SubjectCode'],
      displaySubjectName: json['DisplaySubjectName'],
      teacherName: json['TeacherName'] ?? '',
      employeeCode: json['EmployeeCode'],
      className: json['ClassName'] ?? '',
      classRecNo: json['ClassRecNo'] ?? 0,
      startDate: json['StartDate'],
      endDate: json['EndDate'],
      statusId: json['Status_ID'] ?? 0,
      academicYear: json['Academic_Year'] ?? '',
    );
  }
}

class StudyMaterialStats {
  final int totalMaterials;
  final int totalVideos;
  final int totalWorksheets;
  final int totalRevisionNotes;
  final int totalLessonPlans;
  final int chaptersWithMaterial;

  StudyMaterialStats({
    required this.totalMaterials,
    required this.totalVideos,
    required this.totalWorksheets,
    required this.totalRevisionNotes,
    required this.totalLessonPlans,
    required this.chaptersWithMaterial,
  });

  factory StudyMaterialStats.fromJson(Map<String, dynamic> json) {
    return StudyMaterialStats(
      totalMaterials: json['TotalMaterials'] ?? 0,
      totalVideos: json['TotalVideos'] ?? 0,
      totalWorksheets: json['TotalWorksheets'] ?? 0,
      totalRevisionNotes: json['TotalRevisionNotes'] ?? 0,
      totalLessonPlans: json['TotalLessonPlans'] ?? 0,
      chaptersWithMaterial: json['ChaptersWithMaterial'] ?? 0,
    );
  }
}

class YearComparison {
  final String period;
  final int studentCount;

  YearComparison({
    required this.period,
    required this.studentCount,
  });

  factory YearComparison.fromJson(Map<String, dynamic> json) {
    return YearComparison(
      period: json['Period'] ?? '',
      studentCount: json['StudentCount'] ?? 0,
    );
  }
}

// ============================================================================
// BLOC
// ============================================================================

class SchoolPanelBloc extends Bloc<SchoolPanelEvent, SchoolPanelState> {
  SchoolPanelBloc() : super(SchoolPanelInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboardData(
      LoadDashboardData event,
      Emitter<SchoolPanelState> emit,
      ) async {
    emit(SchoolPanelLoading());

    try {
      final data = await _fetchDashboardData(
        event.schoolRecNo,
        event.academicYear,
      );
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(SchoolPanelError('Failed to load dashboard: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDashboard(
      RefreshDashboard event,
      Emitter<SchoolPanelState> emit,
      ) async {
    add(LoadDashboardData(
      schoolRecNo: event.schoolRecNo,
      academicYear: event.academicYear,
    ));
  }

  Future<DashboardData> _fetchDashboardData(
      int schoolRecNo,
      String academicYear,
      ) async {
    try {
      final url = Uri.parse(
        'https://aquare.co.in/mobileAPI/sachin/lms/school_dashboard.php?Content-Type=application/json',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'School_RecNo': schoolRecNo,
          'Academic_Year': academicYear,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          return DashboardData.fromJson(jsonResponse);
        } else {
          throw Exception(jsonResponse['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
