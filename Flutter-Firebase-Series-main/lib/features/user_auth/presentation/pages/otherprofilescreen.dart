import 'package:InternHeroes/features/user_auth/presentation/pages/ChooseTypePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/userlistpage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/calendar.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/bottom_navbar.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/postdetailspage.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/image_slider.dart';

class OtherProfileScreen extends StatelessWidget {
  final String uid;

  const OtherProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Adjusted length to 3 for three tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'Certificates'), // New tab for Certificates
              Tab(text: 'About'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Posts Tab
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('knowledge_resource')
                  .where('userId',
                  isEqualTo: uid) // Fetch posts where userId matches viewed user's uid
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No posts found for this user.'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var post = snapshot.data!.docs[index];
                    var postData = post.data() as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () {
                        _viewPostDetails(context, post);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          // Display image slider if available
                          if (postData['imageUrls'] != null &&
                              (postData['imageUrls'] as List).isNotEmpty)
                            ImageSlider(imageUrls: List<String>.from(postData['imageUrls'])),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Wrap(
                              spacing: 8,
                              children: (postData['tags'] as List<dynamic>)
                                  .map<Widget>((tag) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Chip(
                                    label: Text(tag),
                                    backgroundColor: Colors.yellow[800],
                                    labelStyle: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: Colors.transparent),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 25.0),
                            child: Text(
                              postData['title'],
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                          SizedBox(height: 1), // Add some space between "Posted by" and "Date Posted"
                          Padding(
                            padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items to the right
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Posted: ',
                                      style: TextStyle(
                                        color: Colors.grey, // Changed color to grey
                                      ),
                                    ),
                                    Text(
                                      _getPostDate(post),
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey, // Changed color to grey
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Center(
                            child: Divider(
                              color: Colors.grey[400],
                              thickness: 1,
                              indent: 20, // Adjusted the start position of the divider
                              endIndent: 20, // Adjusted the end position of the divider
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );

              },
            ),
            // Certificates Tab
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('certificates')
                  .where('userId',
                  isEqualTo: uid) // Filter certificates by user ID
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No certificates found for this user.'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var certificate = snapshot.data!.docs[index];
                    var certificateData = certificate.data() as Map<
                        String,
                        dynamic>;

                    // Check if title and image URL are null
                    var title = certificateData['title'] ?? 'No Title';
                    var imageUrl = certificateData['imageUrl'] ??
                        'https://via.placeholder.com/150'; // Provide a default image URL

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                // Adjusted left padding for the title
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            InkWell(
                              onTap: () {
                                _showImage(context, imageUrl);
                              },
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  // Adjusted horizontal padding
                                  child: Image.network(
                                    imageUrl,
                                    height: 300,
                                    // Increase height for larger size
                                    width: 300,
                                    // Increase width for larger size
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            // Added spacing between image and card bottom
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // About Tab
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Text('User data not found for UID: $uid'),
                  );
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundImage: userData['profileImageUrl'] != null
                                  ? NetworkImage(
                                  userData['profileImageUrl'] as String)
                                  : AssetImage(
                                  'assets/default_profile_image.jpg')
                              as ImageProvider<Object>?,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              userData['name'] as String,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${(userData['careerPath'] as List<dynamic>).join(', ')}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      buildProfileItem('Email', userData['email'] as String?),
                      buildProfileItem('Phone Number',
                          userData['phoneNumber'] as String?),
                      buildProfileItem('Birthday', userData['birthday'] as String?),
                      buildProfileItem('University',
                          userData['university'] as String?),
                      buildProfileItem('Year and Course',
                          userData['yearAndCourse'] as String?),
                      buildProfileItem('OJT Coordinator Email',
                          userData['ojtCoordinatorEmail'] as String?),
                      buildProfileItem('Required Hours',
                          userData['requiredHours'] as String?),
                      buildProfileItem('Career Path',
                          (userData['careerPath'] as List<dynamic>).join(', ')),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: 1, // Profile screen is selected by default
          onItemTapped: (index) {
            // Handle navigation based on index
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => KnowledgeResource()),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => UserListPage()),
                );
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ChooseTypePage()),
                );
                break;
              case 3:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Calendar()),
                );
                break;
              case 4:
              // Profile screen is already open, do nothing
                break;
            }
          },
        ),
      ),
    );
  }

  String _getPostDate(DocumentSnapshot post) {
    Timestamp timestamp = post['datePosted'];
    DateTime postDateTime = timestamp.toDate();
    DateTime now = DateTime.now();

    Duration difference = now.difference(postDateTime);

    if (difference.inDays > 365) {
      int years = (difference.inDays / 365).floor();
      return '$years' + 'y ago';
    } else if (difference.inDays >= 30) {
      int months = (difference.inDays / 30).floor();
      return '$months' + 'm ago';
    } else if (difference.inDays >= 7) {
      int weeks = (difference.inDays / 7).floor();
      return '$weeks' + 'w ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}min ago';
    } else if (difference.inSeconds >= 1) {
      return '${difference.inSeconds}s ago';
    } else {
      return 'just now';
    }
  }

  Widget buildProfileItem(String title, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Text(
          value ?? 'N/A', // Use 'N/A' if value is null
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Divider(
          color: Colors.grey[300],
          thickness: 1,
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.signOut();
                  // Clear cached user data
                  _clearCachedUserData();
                  Navigator.pushReplacementNamed(context, '/login');
                } catch (e) {
                  print("Error logging out: $e");
                }
              },
              child: Text(
                "Yes",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.yellow[800]!),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.all(15)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "No",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.all(15)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearCachedUserData() {
    // No cached user data to clear in this case
  }

  Future<String> _getPostUserName(DocumentSnapshot post) async {
    final userId = post['userId'];
    final userSnapshot = await FirebaseFirestore.instance.collection('users')
        .doc(userId)
        .get();
    return userSnapshot['name'];
  }

  void _viewPostDetails(BuildContext context, DocumentSnapshot post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsPage(post: post),
      ),
    );
  }

  void _showImage(BuildContext context, String imageUrl) {
    FirebaseFirestore.instance
        .collection('certificates')
        .where('imageUrl', isEqualTo: imageUrl)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        String title = querySnapshot.docs.first['title'];
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(title),
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    });
  }
}
