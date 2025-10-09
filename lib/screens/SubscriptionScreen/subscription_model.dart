import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lms_publisher/Theme/apptheme.dart';
import 'package:intl/intl.dart';

// --- UI MODEL (No changes needed) ---
class Plan {
  final String recNo;
  final String subscriptionId;
  final String name;
  final String description;
  final String planType;
  final String currency;
  final double price;
  final String billingCycle;
  final double? discountPercent;
  final int? trialPeriodDays;
  final int usersAllowed;
  final int devicesAllowed;
  final bool isRecordedLectures;
  final bool isAssignmentsTests;
  final bool isDownloadableResources;
  final bool isDiscussionForum;
  final String supportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isAutoRenewal;
  final bool isActive;
  final bool isPopular;
  final List<String> features;

  Plan({
    required this.recNo,
    required this.subscriptionId,
    required this.name,
    required this.description,
    required this.planType,
    required this.currency,
    required this.price,
    required this.billingCycle,
    this.discountPercent,
    this.trialPeriodDays,
    required this.usersAllowed,
    required this.devicesAllowed,
    required this.isRecordedLectures,
    required this.isAssignmentsTests,
    required this.isDownloadableResources,
    required this.isDiscussionForum,
    required this.supportType,
    this.startDate,
    this.endDate,
    required this.isAutoRenewal,
    required this.isActive,
    required this.isPopular,
  }) : features = _generateFeaturesList(
    isRecordedLectures: isRecordedLectures,
    isAssignmentsTests: isAssignmentsTests,
    isDownloadableResources: isDownloadableResources,
    isDiscussionForum: isDiscussionForum,
    supportType: supportType,
  );

  static List<String> _generateFeaturesList({
    required bool isRecordedLectures,
    required bool isAssignmentsTests,
    required bool isDownloadableResources,
    required bool isDiscussionForum,
    required String supportType,
  }) {
    final List<String> featureList = [];
    if (isRecordedLectures) featureList.add("Recorded Lectures");
    if (isAssignmentsTests) featureList.add("Assignments & Tests");
    if (isDownloadableResources) featureList.add("Downloadable Resources");
    if (isDiscussionForum) featureList.add("Discussion Forum");
    if (supportType.isNotEmpty && supportType.toLowerCase() != 'none') {
      featureList.add("$supportType Support");
    }
    return featureList;
  }

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      recNo: json['RecNo'] ?? '',
      subscriptionId: json['Subscription_ID'] ?? '',
      name: json['Subscription_Name'] ?? 'Unnamed Plan',
      description: json['Description'] ?? 'No description.',
      planType: json['Plan_Type'] ?? 'Monthly',
      currency: json['Currency'] ?? 'INR',
      price: double.tryParse(json['Price']?.toString() ?? '0.0') ?? 0.0,
      billingCycle: json['Billing_Cycle'] ?? 'month',
      discountPercent: double.tryParse(json['Discount_Percent']?.toString() ?? '0'),
      trialPeriodDays: int.tryParse(json['Trial_Period_Days']?.toString() ?? '0'),
      usersAllowed: int.tryParse(json['Users_Allowed']?.toString() ?? '0') ?? 0,
      devicesAllowed: int.tryParse(json['Devices_Allowed']?.toString() ?? '0') ?? 0,
      isRecordedLectures: json['Is_Recorded_Lectures'] == '1',
      isAssignmentsTests: json['Is_Assignments_Tests'] == '1',
      isDownloadableResources: json['Is_Downloadable_Resources'] == '1',
      isDiscussionForum: json['Is_Discussion_Forum'] == '1',
      supportType: json['Support_Type'] ?? 'None',
      startDate: DateTime.tryParse(json['Start_Date'] ?? ''),
      endDate: DateTime.tryParse(json['End_Date'] ?? ''),
      isAutoRenewal: json['Is_Auto_Renewal'] == '1',
      isActive: json['Is_Status'] == '1',
      isPopular: json['IsPopular'] == '1',
    );
  }
}

class DashboardData {
  final List<ChartData> monthlyRevenue;
  final List<ChartData> planPopularity;
  final List<Activity> recentActivities;
  final KpiData kpis;

  DashboardData({
    required this.monthlyRevenue,
    required this.planPopularity,
    required this.recentActivities,
    required this.kpis,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    print('🔥 DashboardData.fromJson called');
    print('📦 Full JSON: $json');

    final List<dynamic> mrrRaw = json['MonthlyRevenue'] ?? [];
    print('💰 MonthlyRevenue raw data: $mrrRaw');

    final List<ChartData> mrrData = mrrRaw.map((item) {
      final xValue = item['x'] as String;
      final yString = item['y'].toString();
      final yParsed = double.tryParse(yString) ?? 0.0;

      print('  📊 Processing: x="$xValue", y(raw)="$yString", y(parsed)=$yParsed');

      // ✅ REMOVED THE DIVISION BY 1000 - Keep original values
      return ChartData(xValue, yParsed);
    }).toList();

    print('✅ Final MRR Data:');
    for (var data in mrrData) {
      print('   ${data.x}: ${data.y}');
    }

    final List<dynamic> popularityRaw = json['PlanPopularity'] ?? [];
    print('📈 PlanPopularity raw data: $popularityRaw');

    final List<ChartData> popularityData = popularityRaw
        .map((item) => ChartData(
      item['x'] as String,
      double.tryParse(item['y'].toString()) ?? 0.0,
    ))
        .toList();

    final List<dynamic> activitiesRaw = json['RecentActivities'] ?? [];
    final List<Activity> activityData =
    activitiesRaw.map((item) => Activity.fromJson(item)).toList();

    final KpiData kpiData = KpiData.fromJson(json['KPIs'] ?? {});

    return DashboardData(
      monthlyRevenue: mrrData,
      planPopularity: popularityData,
      recentActivities: activityData,
      kpis: kpiData,
    );
  }
}

class KpiData {
  final String activePlans;
  final String totalRevenue;
  final String subscribers;
  final String expiringSoon;

  KpiData({
    required this.activePlans,
    required this.totalRevenue,
    required this.subscribers,
    required this.expiringSoon,
  });

  factory KpiData.fromJson(Map<String, dynamic> json) {
    print('💳 KpiData.fromJson: $json');

    final numberFormat = NumberFormat.compactCurrency(
      decimalDigits: 2,
      symbol: '₹',
    );
    final revenue = double.tryParse(json['TotalRevenue']?.toString() ?? '0') ?? 0;

    print('💵 Total Revenue parsed: $revenue');
    print('💵 Total Revenue formatted: ${numberFormat.format(revenue)}');

    return KpiData(
      activePlans: json['ActivePlans'] ?? '0',
      totalRevenue: numberFormat.format(revenue),
      subscribers: json['Subscribers'] ?? '0',
      expiringSoon: json['ExpiringSoon'] ?? '0',
    );
  }
}

class Activity {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  Activity({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    IconData iconData = Iconsax.info_circle;
    Color color = AppTheme.bodyText;
    switch (json['ActivityType']) {
      case 'New Subscriber / Renewal':
        iconData = Iconsax.add_circle;
        color = AppTheme.primaryGreen;
        break;
      case 'Plan Upgraded':
        iconData = Iconsax.crown;
        color = AppTheme.mackColor;
        break;
      case 'Payment Failed':
        iconData = Iconsax.warning_2;
        color = Colors.orange;
        break;
    }

    String formatActivityTime(String activityTime) {
      try {
        final dateTime = DateTime.parse(activityTime);
        final difference = DateTime.now().difference(dateTime);
        if (difference.inMinutes < 1) return 'Just now';
        if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
        if (difference.inHours < 24) return '${difference.inHours}h ago';
        return '${difference.inDays}d ago';
      } catch (e) {
        return '';
      }
    }

    return Activity(
      icon: iconData,
      iconColor: color,
      title: '${json['ActivityType']}',
      subtitle: '${json['SchoolName']} - ${json['PlanName']}',
      time: formatActivityTime(json['ActivityTime']),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y) {
    print('🎯 ChartData created: x="$x", y=$y');
  }

  final String x;
  final double y;
}
