import 'package:intl/intl.dart';
class DashboardData {
  final int lifetimeTotal;
  final int totalReferral;
  final int pendingReferral;
  final int availableBalance;
  final int completedSurvey;
  final int donated;
  final List<Survey> surveys;
  final Stats stats;

  DashboardData({
    required this.lifetimeTotal,
    required this.totalReferral,
    required this.pendingReferral,
    required this.availableBalance,
    required this.completedSurvey,
    required this.donated,
    required this.surveys,
    required this.stats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      lifetimeTotal: json['lifetime_total'] ?? 0,
      totalReferral: json['total_referral'] ?? 0,
      pendingReferral: json['pending_referral'] ?? 0,
      availableBalance: json['available_balance'] ?? 0,
      completedSurvey: json['completed_survey'] ?? 0,
      donated: json['donated'] ?? 0,
      surveys: (json['surveys'] as List?)
              ?.map((s) => Survey.fromJson(s))
              .toList() ??
          [],
      stats: Stats.fromJson(json['stats'] ?? {}),
    );
  }
}

class Survey {
  final int id;
  final String title;
  final int reward;
  final String type;
  final String description;
  final String createdAt;

  Survey({
    required this.id,
    required this.title,
    required this.reward,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      reward: json['reward'] ?? 0,
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Stats {
  final int thisWeek;
  final int thisMonth;
  final int thisYear;

  Stats({
    required this.thisWeek,
    required this.thisMonth,
    required this.thisYear,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      thisWeek: json['this_week'] ?? 0,
      thisMonth: json['this_month'] ?? 0,
      thisYear: json['this_year'] ?? 0,
    );
  }
}

// Completed Survey Model
class CompletedSurvey {
  final int id;
  final String date;
  final int surveyId;
  final int surveyAmount;
  final String response;
  final int status;
  final String surveyTitle;
  final String surveyType;
  final String surveyDescription;

  CompletedSurvey({
    required this.id,
    required this.date,
    required this.surveyId,
    required this.surveyAmount,
    required this.response,
    required this.status,
    required this.surveyTitle,
    required this.surveyType,
    required this.surveyDescription,
  });

  factory CompletedSurvey.fromJson(Map<String, dynamic> json) {
    return CompletedSurvey(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      surveyId: json['survey_id'] ?? 0,
      surveyAmount: json['survey_amount'] ?? 0,
      response: json['response'] ?? '',
      status: json['status'] ?? 0,
      surveyTitle: json['survey_title'] ?? '',
      surveyType: json['survey_type'] ?? '',
      surveyDescription: json['survey_description'] ?? '',
    );
  }

  String get statusText {
    switch (status) {
      case 6:
        return 'Completed';
      case 5:
        return 'Pending';
      case 4:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }
}

// Referral Model
class Referral {
  final String fullname;
  final String country;

  Referral({
    required this.fullname,
    required this.country,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      fullname: json['fullname'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

// Transaction Model


class Transaction {
  final int id;
  final DateTime date;
  final String transactionType;
  final String method;
  final String accountDetails;
  final double amount;
final int status2;
  Transaction({
    required this.id,
    required this.date,
    required this.transactionType,
    required this.method,
    required this.accountDetails,
    required this.amount,
    required this.status2,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      date: _parseDate(json['date']).toLocal(),
      transactionType: json['transaction_type'] ?? '',
      method: json['method'] ?? '',
      accountDetails: json['account_details'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status2: json['status'] ?? 0,
    );
  }

  static DateTime _parseDate(String dateString) {
    try {
      final formatter = DateFormat("yyyy-MM-dd HH:mm:ss");
      return formatter.parseUtc(dateString);
    } catch (e) {
      return DateTime.parse(dateString);
    }
  }

  // Convert date to string for UI
  String getFormattedDate() {
    final formatter = DateFormat('dd/MM/yyyy hh:mm a');
    return formatter.format(date.toLocal());
  }

  // Compute status based on days difference
  String get statusText {
    final daysPassed = DateTime.now().difference(date).inDays;

    if (daysPassed < 4) {
      return 'Pending';
    } else if (daysPassed < 6) {
      return 'Approved';
    } else if (daysPassed < 10) {
      return 'Processing';
    } else if (daysPassed < 14) {
      return 'Completed';
    }else if (daysPassed < 17) {
      return 'Bounced Back';
    }    else {
      return 'Refunded';
    }
  }

  // Optional: badge color for UI Widgets
  String get statusBadgeClass {
    final daysPassed = DateTime.now().difference(date).inDays;

    if (daysPassed < 4) {
      return 'pending'; // equivalent to bg-warning text-dark
    } else if (daysPassed < 6) {
      return 'approved'; // bg-info text-white
    } else if (daysPassed < 10) {
      return 'processing'; // bg-primary text-white
    } else {
      return 'completed'; // bg-success text-white
    }
  }



  String get methodFormatted {
    switch (method.toLowerCase()) {
      case 'paypal':
        return 'PayPal';
      case 'bank':
        return 'Bank Transfer';
      case 'crypto':
        return 'Cryptocurrency';
      default:
        return method;
    }
  }
}