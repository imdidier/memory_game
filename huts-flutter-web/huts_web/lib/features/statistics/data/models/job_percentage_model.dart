import 'package:huts_web/features/statistics/domain/entities/job_percentage.dart';

class JobPercentageModel extends JobPercentage {
  JobPercentageModel({
    required super.count,
    required super.jobValue,
    required super.jobName,
  });

  factory JobPercentageModel.fromMap(Map<String, dynamic> map) {
    return JobPercentageModel(
      count: 1,
      jobValue: map['details']['job']['value'],
      jobName: map['details']['job']['name'],
    );
  }
}
