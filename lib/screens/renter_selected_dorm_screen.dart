import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormbnb/utils/color_util.dart';
import 'package:dormbnb/widgets/app_bar_widget.dart';
import 'package:dormbnb/widgets/custom_miscellaneous_widgets.dart';
import 'package:dormbnb/widgets/custom_padding_widgets.dart';
import 'package:dormbnb/widgets/custom_text_widgets.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../providers/loading_provider.dart';
import '../providers/rentals_provider.dart';
import '../utils/future_util.dart';
import '../utils/navigator_util.dart';
import '../utils/string_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:dormbnb/screens/rating_review_screen.dart' as dex;

// import 'package:dormbnb/screens/user_review_list_screen.dart';
// import 'package:dormbnb/models/review.dart';

// import 'package:firebase_database/firebase_database.dart';

// import 'package:dormbnb/firebase_options.dart';
import 'package:intl/intl.dart';

Widget _buildRatingStars(rating) {
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

class SelectedDormScreen extends ConsumerStatefulWidget {
  final String dormID;
  const SelectedDormScreen({super.key, required this.dormID});

  @override
  ConsumerState<SelectedDormScreen> createState() => _SelectedDormScreenState();
}

class _SelectedDormScreenState extends ConsumerState<SelectedDormScreen> {
  double __rating = 0.0;
  TextEditingController _reviewController = TextEditingController();
  //  DORM VARIABLES
  String name = '';
  String address = '';
  String description = '';
  num monthlyRent = 0;
  List<dynamic> imageURLs = [];
  bool isRentingThisVehicle = false;

  //  LOCAL VARIABLES
  final List<Map<String, String>> reviews = [];

  List dormReviewsDocs = [];
  int currentImageIndex = 0;
  double averageRating = 0.0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        final dorm = await getThisDormDoc(widget.dormID);

        double totalRating = 0.0;

        print(widget.dormID);
        dormReviewsDocs = await getAllDormReviews(widget.dormID);

        print(dormReviewsDocs.length);

        int numberOfReviews = dormReviewsDocs.length;

        if (numberOfReviews > 0) {
          for (var doc in dormReviewsDocs) {
            totalRating += doc['rating'];
          }

          averageRating = totalRating / numberOfReviews;
        }

        print(averageRating);

        final dormData = dorm.data() as Map<dynamic, dynamic>;
        name = dormData[DormFields.name];
        address = dormData[DormFields.address];
        description = dormData[DormFields.description];
        imageURLs = dormData[DormFields.dormImageURLs];
        monthlyRent = dormData[DormFields.monthlyRent];
        isRentingThisVehicle = await isCurrentlyRentingThisDorm(widget.dormID);
        ref.read(loadingProvider).toggleLoading(false);

        // await readReviews();
      } catch (error) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting selected dorm detials: $error')));
        ref.read(loadingProvider).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
        appBar: appBarWidget(hasLeading: true),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: isRentingThisVehicle
              ? blackHelveticaBold('You have already requested this dorm',
                  fontSize: 16)
              : ElevatedButton(
                  onPressed: () {
                    ref.read(rentalsProvider).setSelectedDormID(widget.dormID);
                    Navigator.of(context)
                        .pushNamed(NavigatorRoutes.renterNewRental);
                  },
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  child: whiteHelveticaBold('BOOK', fontSize: 24)),
        ),
        body: switchedLoadingContainer(
            ref.read(loadingProvider).isLoading,
            SingleChildScrollView(
                child: Column(children: [
              _dormHeader(),
              if (imageURLs.isNotEmpty) _dormImages(),
              _dormDescription(),
              _rating(averageRating),
              _dormReviews()
            ]))));
  }

  Widget _dormHeader() {
    return all10Pix(
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              blackHelveticaBold(name, fontSize: 24),
              blackHelveticaBold(address,
                  fontSize: 14, textAlign: TextAlign.left)
            ])),
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: blackHelveticaBold('${formatPrice(monthlyRent.toDouble())}',
                fontSize: 30))
      ]),
    );
  }

  Widget _dormImages() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          all10Pix(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 300,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  image: DecorationImage(
                      image: NetworkImage(imageURLs[currentImageIndex]),
                      fit: BoxFit.cover)),
            ),
          ),
          Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  onPressed: () {
                    if (currentImageIndex == 0) return;
                    setState(() {
                      currentImageIndex--;
                    });
                  },
                  icon: Icon(Icons.arrow_left, color: CustomColors.tangerine))),
          Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                  onPressed: () {
                    if (currentImageIndex == imageURLs.length - 1) {
                      return;
                    }
                    setState(() {
                      currentImageIndex++;
                    });
                  },
                  icon: Icon(Icons.arrow_right, color: CustomColors.tangerine)))
        ],
      ),
    );
  }

  Widget _dormDescription() {
    return vertical10Pix(
      child: Container(
          width: double.infinity,
          decoration: BoxDecoration(border: Border.all()),
          padding: const EdgeInsets.all(4),
          child: blackHelveticaRegular(description, textAlign: TextAlign.left)),
    );
  }

  Widget _rating(double averageRating) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(50)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              RatingBarIndicator(
                rating: averageRating,
                itemBuilder: (context, index) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                itemCount: 5,
                itemSize: 30.0,
                direction: Axis.horizontal,
              ),
            ],
          ),
          horizontal5Pix(
              child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 16,
                          child: Container(
                            child: ListView(
                              shrinkWrap: true,
                              children: <Widget>[
                                SizedBox(height: 20),
                                // Center(child: Text('Leaderboard')),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize
                                        .min, // Ensures Column takes up minimum space needed
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center, // Center-aligns children horizontally
                                    children: <Widget>[
                                      Text(
                                        'Please rate the dorm',
                                        style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 16.0),
                                      Center(
                                        child: RatingBar.builder(
                                          initialRating: __rating,
                                          minRating: 1,
                                          direction: Axis.horizontal,
                                          allowHalfRating: true,
                                          itemCount: 5,
                                          itemPadding: EdgeInsets.symmetric(
                                              horizontal: 4.0),
                                          itemBuilder: (context, _) => Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                          onRatingUpdate: (rating) {
                                            setState(() {
                                              __rating = rating;
                                            });
                                          },
                                        ),
                                      ),
                                      SizedBox(height: 24.0),
                                      Text(
                                        'Write a review',
                                        style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 16.0),
                                      Column(
                                        children: [],
                                      ),
                                      TextField(
                                        controller: _reviewController,
                                        maxLines: 4,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Share your experience...',
                                        ),
                                      ),
                                      SizedBox(height: 24.0),
                                      Center(
                                        child: ElevatedButton(
                                            onPressed: () async {
                                              if (_reviewController
                                                  .text.isNotEmpty) {
                                                // Handle the review submission logic here
                                                print('Ratings: $__rating');
                                                print(
                                                    'Review: ${_reviewController.text}');

                                                try {
                                                  // Prepare the review data
                                                  Map<String, dynamic>
                                                      reviewData = {
                                                    'userID': FirebaseAuth
                                                        .instance
                                                        .currentUser!
                                                        .uid,
                                                    'dormID': widget.dormID,
                                                    'description':
                                                        _reviewController.text,
                                                    'rating': __rating,
                                                    'dateCreated': FieldValue
                                                        .serverTimestamp(), // Automatically set the timestamp to now
                                                  };

                                                  // Add the review to the 'reviews' collection
                                                  FirebaseFirestore firestore =
                                                      FirebaseFirestore
                                                          .instance;
                                                  await firestore
                                                      .collection('reviews')
                                                      .add(reviewData);

                                                  Navigator.of(context)
                                                      .pop(); // Closes the dialog

                                                  print(
                                                      'Review added successfully.');
                                                  dormReviewsDocs =
                                                      await getAllDormReviews(
                                                          widget.dormID);
                                                  ;
                                                  // SnackBar(
                                                  //     content: Text(
                                                  //         'Review submitted!'));
                                                } catch (e) {
                                                  print(
                                                      'Error adding review: $e');
                                                }

                                                // ScaffoldMessenger.of(context)
                                                //     .showSnackBar(
                                                //   SnackBar(
                                                //       content: Text(
                                                //           'Review submitted!')),
                                                // );
                                                // Clear the review after submission
                                                _reviewController.clear();
                                                setState(() {
                                                  __rating = 0.0;
                                                });
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Please enter a review.')),
                                                );
                                              }
                                            },
                                            child: whiteHelveticaBold(
                                                'Submit Review')),
                                      ),
                                      SizedBox(height: 24.0),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  child: whiteHelveticaBold('Review')))
        ],
      ),
    );
  }

  Widget _dormReviews() {
    return all20Pix(
        child: Container(
      width: double.infinity,
      // decoration: BoxDecoration(
      //     color: CustomColors.pearlWhite,
      //     borderRadius: BorderRadius.circular(10)),
      // padding: EdgeInsets.all(5),
      child: Column(
        children: [
          // blackHelveticaBold('DORM REVIEWS', fontSize: 24),
          // const Divider(color: Colors.black),
          // blackHelveticaRegular('No Reviews Available'),
          SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  child: dormReviewsDocs.isNotEmpty
                      ? ListView.builder(
                          itemCount: dormReviewsDocs.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final review = dormReviewsDocs[index];

                            DateTime dateTime = review['dateCreated'].toDate();

                            // Format DateTime to a readable string
                            String formattedDate =
                                DateFormat('MMMM dd, yyyy - hh:mm a')
                                    .format(dateTime);

                            // final userID = review['userID'];

                            // final ownerDoc = getThisUserDoc(userID);
                            // final ownerData =
                            //     ownerDoc.data() as Map<dynamic, dynamic>;
                            // final formattedName =
                            //     '${ownerData[UserFields.firstName]} ${ownerData[UserFields.lastName]}';
                            return Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.blueAccent,
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 20.0,
                                            ),
                                            radius: 12.0,
                                          ),
                                          SizedBox(width: 10), // give it width
                                          Text(
                                            review['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      _buildRatingStars(
                                        review['rating'],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    review['description'],
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          })
                      : vertical20Pix(
                          child: blackHelveticaBold('No Reviews available',
                              fontSize: 30)),
                )
              ],
            ),
          )
        ],
      ),
    ));
  }
}
