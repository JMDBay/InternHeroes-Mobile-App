import 'dart:io';
import 'package:InternHeroes/features/user_auth/presentation/pages/ChooseTypePage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/dashboardpage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/postdetailscerts.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/userlistpage.dart';
import 'calendar.dart';
import 'editableprofilescreen.dart';
import 'dart:typed_data';
import 'package:InternHeroes/features/user_auth/presentation/widgets/bottom_navbar.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/postdetailspage.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/image_slider.dart';
import 'package:intl/intl.dart';


class ProfileScreen extends StatefulWidget {
  final String uid;
  final String placeholderImageUrl = 'assets/superhero.jpg';
  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  Map<String, dynamic>? userData;
  final picker = ImagePicker();
  int _currentImageIndex = 0;
  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _uploadImageToFirebase() async {
    if (_image == null) return;

    try {
      print('Starting image upload...');
      // Read the file as bytes
      List<int> imageBytes = await _image!.readAsBytes();

      // Convert List<int> to Uint8List
      Uint8List uint8List = Uint8List.fromList(imageBytes);

      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('user_profile_images/${widget.uid}.jpg');

      // Upload the image data as bytes
      await storageReference.putData(uint8List);

      // Get the download URL for the uploaded image
      String downloadURL = await storageReference.getDownloadURL();

      // Update the user document in Firestore with the download URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({
        'profileImageUrl': downloadURL,
      });

      print('Image uploaded to Firebase Storage and URL saved to Firestore.');
    } catch (e) {
      print('Error uploading image to Firebase Storage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.dashboard),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text('User data not found for UID: ${widget.uid}'),
            );
          }

          Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              GestureDetector(
                onTap: getImage,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.yellow[800]!, // Border color is black
                      width: 0, // Reduced border width to 1.0
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : userData['profileImageUrl'] != null
                        ? NetworkImage(userData['profileImageUrl'] as String)
                        : null as ImageProvider<Object>?,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                userData['name'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                (userData['careerPath'] as List<dynamic>?)?.join(', ') ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey, // Changed font color to grey
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Expanded(
                child: DefaultTabController(
                  length: 4, // Updated length to 4 for four tabs
                  child: Column(
                    children: <Widget>[
                      Container(
                        constraints: BoxConstraints.expand(height: 50),
                        child: TabBar(
                          tabs: [
                            Tab(text: 'Posts'),
                            Tab(text: 'Bookmarks'),
                            Tab(text: 'Certificates'),
                            Tab(text: 'About'),
                          ],
                          labelStyle: TextStyle(fontSize: 9), // Set the font size here
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Posts Tab
                            _buildPostsTab(),
                            // Bookmarks Tab
                            _buildBookmarksTab(),
                            // Certificates Tab
                            _buildCertificatesTab(),
                            // User Details Tab
                            _buildDetailsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10), // Added bottom margin below the tabs
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4, // Profile screen is selected by default
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
    );
  }




  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
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
              child: Text('User data not found for UID: ${widget.uid}'),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _uploadImageToFirebase();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditableProfileScreen(uid: widget.uid)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    backgroundColor: Colors.yellow[800],
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
              buildProfileItem('Email', userData['email']),
              buildProfileItem('Phone Number', userData['phoneNumber']),
              buildProfileItem('Birthday', userData['birthday']),
              buildProfileItem('University', userData['university']),
              buildProfileItem('Year and Course', userData['yearAndCourse']),
              buildProfileItem('OJT Coordinator Email', userData['ojtCoordinatorEmail']),
              buildProfileItem('Required Hours', userData['requiredHours']),
              const SizedBox(height: 20),
            ],
          );
        },
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


  Widget _buildBookmarksTab() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('bookmarks')
          .doc(widget.uid)
          .collection('user_bookmarks')
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
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No bookmarked posts'),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> bookmarkData =
            snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchBookmarkedPosts(bookmarkData),
              builder: (context, AsyncSnapshot<List<DocumentSnapshot>> postSnapshot) {
                if (postSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) {
                  return SizedBox.shrink(); // Return an empty widget if the post doesn't exist
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: postSnapshot.data!.map((post) {
                    return GestureDetector(
                      onTap: () {
                        if (post['postType'] == 'knowledge_resource') {
                          _viewPostDetails(context, post);
                        } else {
                          _viewPostCertDetails(context, post);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          if (post['imageUrls'] != null &&
                              (post['imageUrls'] as List).isNotEmpty)
                            ImageSlider(imageUrls: List<String>.from(post['imageUrls'])),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Wrap(
                              spacing: 8,
                              children: (post['tags'] as List<dynamic>)
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
                              post['title'],
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                          SizedBox(height: 1),
                          Padding(
                            padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Posted by: ',
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _getPostDate(post),
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
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
                              indent: 20,
                              endIndent: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _fetchBookmarkedPosts(Map<String, dynamic> bookmarkData) async {
    final knowledgeResourceDoc = await FirebaseFirestore.instance
        .collection('knowledge_resource')
        .doc(bookmarkData['postId'])
        .get();
    final coursesDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(bookmarkData['postId'])
        .get();

    List<DocumentSnapshot> posts = [];
    if (knowledgeResourceDoc.exists) {
      posts.add(knowledgeResourceDoc);
    }
    if (coursesDoc.exists) {
      posts.add(coursesDoc);
    }

    return posts;
  }





  Widget _buildPostsTab() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('knowledge_resource')
          .where('userId', isEqualTo: widget.uid) // Filter posts by user ID
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No posts available'),
          );
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var post = snapshot.data!.docs[index];
              return GestureDetector(
                onTap: () {
                  // Handle card click action here
                  _viewPostDetails(context, post);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    // Display image slider if available
                    if (post['imageUrls'] != null &&
                        (post['imageUrls'] as List).isNotEmpty)
                      ImageSlider(imageUrls: List<String>.from(post['imageUrls'])),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Wrap(
                        spacing: 8,
                        children: (post['tags'] as List<dynamic>)
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
                        post['title'],
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
                                'Posted by: ',
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
                          GestureDetector(
                            onTap: () {
                              // Show delete confirmation dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Delete Post'),
                                  content: Text('Are you sure you want to delete this post?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog
                                      },
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        // Delete the post
                                        await _deletePost(post.id); // Pass postId to _deletePost method
                                        Navigator.of(context).pop(); // Close the dialog
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red, // Set delete button text color to red
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
        }
      },
    );
  }





  Future<String> _getPostUserName(DocumentSnapshot post) async {
    final userId = post['userId'];
    final userSnapshot = await FirebaseFirestore.instance.collection('users')
        .doc(userId)
        .get();
    return userSnapshot['name'];
  }

  void _showDeleteConfirmationDialog(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deletePost(postId); // Delete the post
              },
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('knowledge_resource')
          .doc(postId)
          .delete();
      print('Post deleted successfully');
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  Widget buildProfileItem(String title, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        if (title == 'Career Path' &&
            value is List<dynamic>) // Check if the value is a list
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: value.map((item) {
              return Row(
                children: [
                  Text(
                    '$item',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 10), // Add spacing between items
                  Text(
                    '|',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey), // Separator style
                  ),
                  SizedBox(width: 10), // Add spacing between items
                ],
              );
            }).toList(),
          ),
        if (title !=
            'Career Path') // If it's not career path, treat it as a regular string
          Text(
            value ?? '',
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

  // Inside your logout function where you sign out the user
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
                backgroundColor:
                MaterialStateProperty.all<Color>(Colors.yellow[800]!),
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
                backgroundColor:
                MaterialStateProperty.all<Color>(Colors.white),
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

  // Function to clear cached user data
  void _clearCachedUserData() {
    setState(() {
      _image = null; // Clear the profile picture
    });
  }

  void _removeBookmark(String postId) {
    FirebaseFirestore.instance
        .collection('bookmarks')
        .doc(widget.uid)
        .collection('user_bookmarks')
        .doc(postId)
        .delete();
  }

  // Function to navigate to the post details page
  void _viewPostDetails(BuildContext context, DocumentSnapshot post) {
    // Navigate to the post details page, you can replace `PostDetailsPage` with your actual page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsPage(post: post),
      ),
    );
  }

  void _viewPostCertDetails(BuildContext context, DocumentSnapshot post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsCertsPage(post: post),
      ),
    );
  }


  // Method to build the Certificates Tab
  Widget _buildCertificatesTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display existing certificates here
              // You can retrieve and display certificates from Firestore here
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('certificates')
                    .where(
                    'userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return Center(child: CircularProgressIndicator());
                    default:
                      return Column(
                        children: snapshot.data!.docs.map<Widget>((DocumentSnapshot document) {
                          Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Card(
                              elevation: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(data['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                  SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () {
                                      _viewCertificateImage(context, data['title'], data['imageUrl']);
                                    },
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0), // Adjusted horizontal padding
                                        child: Image.network(
                                          data['imageUrl'],
                                          height: 300, // Adjust height for larger size
                                          width: 300, // Adjust width for larger size
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 10), // Added spacing between image and card bottom
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                  }
                },
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: FloatingActionButton(
            onPressed: () {
              _addCertificate();
            },
            backgroundColor: Colors.orange, // Set button color to orange
            child: Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _viewCertificateImage(BuildContext context, String title, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title), // Display the title in the AppBar
          ),
          body: Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }




  Future<void> _addCertificate() async {
    // Show dialog to get certificate title from user
    String? title = await _showAddCertificateDialog();

    if (title != null && title.isNotEmpty) {
      // Certificate title is valid, proceed with adding to Firestore
      print('Certificate title: $title');
    } else {
      print('Certificate title is empty or null');
    }
  }

  Future<String?> _showAddCertificateDialog() async {
    TextEditingController _titleController = TextEditingController();

    File? _image;
    final picker = ImagePicker();

    Future getImage() async {
      final pickedFile = await picker.getImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    }

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Certificate'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: () async {
                      await getImage();
                      setState(() {}); // Update the dialog to reflect the new image
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo),
                        SizedBox(width: 8),
                        Text('Add Image'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_image != null) ...[
                    Expanded(
                      child: Image.file(_image!), // Display the selected image
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Certificate Title'),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Validate that title is not empty and image is selected
                    if (_titleController.text.trim().isEmpty) {
                      print('Certificate title cannot be empty');
                      return;
                    }
                    if (_image == null) {
                      print('Please select an image');
                      return;
                    }

                    // Upload image if selected
                    try {
                      Reference storageReference = FirebaseStorage.instance
                          .ref()
                          .child('certificates/${DateTime.now()}.jpg');

                      UploadTask uploadTask = storageReference.putFile(_image!);

                      // Show loading indicator while uploading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      await uploadTask.whenComplete(() async {
                        // Close loading indicator dialog
                        Navigator.of(context).pop();

                        String downloadURL = await storageReference.getDownloadURL();

                        // Add the certificate data to Firestore
                        await FirebaseFirestore.instance.collection('certificates').add({
                          'userId': FirebaseAuth.instance.currentUser!.uid,
                          'title': _titleController.text.trim(),
                          'imageUrl': downloadURL,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        print('Certificate added successfully');
                      });
                    } catch (e) {
                      print('Error adding certificate: $e');
                    }

                    // Close the dialog and pass the certificate title
                    Navigator.of(context).pop(_titleController.text.trim());
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
