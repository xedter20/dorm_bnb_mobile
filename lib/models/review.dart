// lib/models/review.dart

class Review {
  final String username;
  final String reviewText;
  final double rating;
  final DateTime date;

  Review({
    required this.username,
    required this.reviewText,
    required this.rating,
    required this.date,
  });
}
