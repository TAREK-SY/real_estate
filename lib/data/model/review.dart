import '../../core/functions/json_parsers.dart';

class Review {
  const Review({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    rating: jsonDouble(json['rating']) ?? 0,
    comment: jsonString(json['comment'])?.trim() ?? '',
    reviewerName: jsonString(json['reviewerName'])?.trim() ?? '',
    date: DateTime.tryParse(jsonString(json['date']) ?? ''),
  );

  final double rating;
  final String comment;
  final String reviewerName;
  final DateTime? date;
}
