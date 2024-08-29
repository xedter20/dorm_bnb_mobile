import 'package:flutter/material.dart';

class RateAndReviewCard extends StatelessWidget {
  final String userName;
  final String reviewDescription;
  final String reviewDate;
  final double rating;

  RateAndReviewCard({
    required this.userName,
    required this.reviewDescription,
    required this.reviewDate,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildRatingStars(rating),
              ],
            ),
            SizedBox(height: 5),
            Text(
              reviewDate,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              reviewDescription,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.amber));
    }

    if (hasHalfStar) {
      stars.add(Icon(Icons.star_half, color: Colors.amber));
    }

    while (stars.length < 5) {
      stars.add(Icon(Icons.star_border, color: Colors.amber));
    }

    return Row(children: stars);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Rate and Review")),
        body: ListView(
          children: [
            RateAndReviewCard(
              userName: 'John Doe',
              reviewDescription:
                  'This product is fantastic! Highly recommended.',
              reviewDate: 'August 28, 2024',
              rating: 4.5,
            ),
            RateAndReviewCard(
              userName: 'Jane Smith',
              reviewDescription:
                  'Good product, but it could use some improvements.',
              reviewDate: 'August 25, 2024',
              rating: 3.0,
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MyApp());
