import 'package:InternHeroes/features/user_auth/presentation/pages/ChooseTypePage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/postdetailscerts.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/home_page.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/calendar.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/postdetailspage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/userlistpage.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/bottom_navbar.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/image_slider.dart';

class KnowledgeResource extends StatefulWidget {
  // Define the allTags list as a class variable
  final List<String> allTags = [
    "UI/UX",
    "Vercel",
    "Webflow",
    "Flutter",
    "Programming",
    "Database Manager",
    "System Administrator",
    "Quality Assurance",
    "Service Assurance",
    // Add more tags as needed
  ];

  @override
  _KnowledgeResourceState createState() => _KnowledgeResourceState();
}

class _KnowledgeResourceState extends State<KnowledgeResource> {
  late TextEditingController _searchController;
  late Query _postsQuery;
  late Stream<QuerySnapshot> _postsStream;
  late List<String> _selectedTags; // Define _selectedTags here
  late Query _postsQueryCourses;
  late Stream<QuerySnapshot> _postsStreamCourses;


  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _postsQuery = FirebaseFirestore.instance.collection('knowledge_resource');
    _postsStream = _postsQuery.snapshots();
    _selectedTags = []; // Initialize selected tags list

    _postsQueryCourses = FirebaseFirestore.instance.collection('courses');
    _postsStreamCourses = _postsQueryCourses.snapshots();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Resources',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Making the title text bold
          ),
        ),
        centerTitle: true, // Centering the title text
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey), // Add border
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by title',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            _searchPosts(_searchController.text);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterDialog(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Text(
                  'Knowledge Resource',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Tab(
                child: Text(
                  'Courses & Certificates',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPostsTab(),
                _buildCoursesTab(),
              ],
            ),
          ),
        ],
      ),
    ),

      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          _handleNavigation(context, index);
        },
      ),
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder(
      stream: _postsStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No knowledge resources available'),
          );
        } else {
          // Filter only the posts with status 'accepted'
          final acceptedPosts = snapshot.data!.docs.where((post) => post['status'] == 'approved').toList();

          if (acceptedPosts.isEmpty) {
            return Center(
              child: Text('No accepted knowledge resources available'),
            );
          }

          return ListView.builder(
            itemCount: acceptedPosts.length,
            itemBuilder: (context, index) {
              var post = acceptedPosts[index];
              return FutureBuilder(
                future: _isPostBookmarked(post),
                builder: (context, AsyncSnapshot<bool> bookmarkSnapshot) {
                  if (bookmarkSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (bookmarkSnapshot.hasError) {
                    return Text('Error: ${bookmarkSnapshot.error}');
                  } else {
                    final isBookmarked = bookmarkSnapshot.data ?? false;
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
                            ImageSlider(
                                imageUrls: List<String>.from(post['imageUrls'])),
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
                          // Add some space between "Posted by" and "Date Posted"
                          Padding(
                            padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              // Align items to the right
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
                                IconButton(
                                  icon: Icon(
                                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    color: isBookmarked ? Colors.orange : Colors.grey,
                                  ),
                                  onPressed: () {
                                    _toggleBookmark(post);
                                  },
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
                              // Adjusted the start position of the divider
                              endIndent: 20, // Adjusted the end position of the divider
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }



  Future<bool> _isPostBookmarked(DocumentSnapshot post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bookmarkRef = FirebaseFirestore.instance
          .collection('bookmarks')
          .doc(user.uid)
          .collection('user_bookmarks')
          .doc(post.id);
      final doc = await bookmarkRef.get();
      return doc.exists;
    }
    return false;
  }



  Widget _buildCoursesTab() {
    return StreamBuilder(
      stream: _postsStreamCourses,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No courses available'),
          );
        } else {
          // Filter only the posts with status 'approved'
          final approvedCourses = snapshot.data!.docs.where((post) => post['status'] == 'approved').toList();

          if (approvedCourses.isEmpty) {
            return Center(
              child: Text('No approved courses available'),
            );
          }
          return ListView.builder(
            itemCount: approvedCourses.length,
            itemBuilder: (context, index) {
              var post = approvedCourses[index];
              return GestureDetector(
                onTap: () {
                  _viewPostCertDetails(context, post);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    // Display image slider if available
                    if (post['imageUrls'] != null &&
                        (post['imageUrls'] as List).isNotEmpty)
                      ImageSlider(
                          imageUrls: List<String>.from(post['imageUrls'])),
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
                    // Add some space between "Posted by" and "Date Posted"
                    Padding(
                      padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // Align items to the right
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
                          IconButton(
                            icon: FutureBuilder(
                              future: _isPostBookmarked(post),
                              builder: (context, AsyncSnapshot<bool> bookmarkSnapshot) {
                                if (bookmarkSnapshot.connectionState == ConnectionState.waiting) {
                                  return Icon(Icons.bookmark_border);
                                } else if (bookmarkSnapshot.hasData) {
                                  final isBookmarked = bookmarkSnapshot.data!;
                                  return Icon(
                                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    color: isBookmarked ? Colors.orange : Colors.grey,
                                  );
                                } else {
                                  return Icon(Icons.bookmark_border);
                                }
                              },
                            ),
                            onPressed: () {
                              _toggleBookmarkCourses(post);
                            },
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
                        // Adjusted the start position of the divider
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


  void _toggleBookmarkCourses(DocumentSnapshot post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bookmarkRef = FirebaseFirestore.instance.collection('bookmarks')
          .doc(user.uid)
          .collection('user_bookmarks')
          .doc(post.id);

      if (await bookmarkRef.get().then((doc) => doc.exists)) {
        bookmarkRef.delete();
      } else {
        bookmarkRef.set({
          'postId': post.id,
          'title': post['title'],
          // Add other necessary fields from the post
        });
      }
    }
  }





  Widget _buildPostItem(DocumentSnapshot post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: GestureDetector(
            onTap: () {
              _viewPostDetails(context, post);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _buildTagChips(post['tags']),
                ),
                SizedBox(height: 10),
                if (post['imageUrls'] != null && post['imageUrls'].isNotEmpty) // Check if imageUrls is not empty
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: post['imageUrls'].map<Widget>((imageUrl) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.network(
                            imageUrl,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: 5),
                _buildPostedByRow(post),
              ],
            ),
          ),
        ),
        Divider(
          color: Colors.grey,
          thickness: 1,
        ),
      ],
    );
  }


  List<Widget> _buildTagChips(List<dynamic> tags) {
    return tags.map<Widget>((tag) {
      if (tag is String) {
        return Chip(
          label: Text(
            tag,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.yellow[800],
          labelStyle: TextStyle(
            fontSize: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.transparent),
          ),
        );
      } else {
        return Container(); // Handle non-string tags
      }
    }).toList();
  }

  Widget _buildPostedByRow(DocumentSnapshot post) {
    return Row(
      children: [
        Text(
          'Posted by: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        FutureBuilder(
          future: _getPostUserName(post),
          builder: (context, AsyncSnapshot<String> userNameSnapshot) {
            if (userNameSnapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (userNameSnapshot.hasData) {
              return Text(
                userNameSnapshot.data!,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              );
            } else {
              return Text(
                'Unknown',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              );
            }
          },
        ),
      ],
    );
  }




  Future<String> _getPostUserName(DocumentSnapshot post) async {
    final userId = post['userId'];
    final userSnapshot = await FirebaseFirestore.instance.collection('users')
        .doc(userId)
        .get();
    return userSnapshot['name'];
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

  void _searchPosts(String query) {
    setState(() {
      Query filteredQueryKnowledgeResource =
      FirebaseFirestore.instance.collection('knowledge_resource');
      Query filteredQueryCourses =
      FirebaseFirestore.instance.collection('courses');

      if (query.isNotEmpty) {
        filteredQueryKnowledgeResource = filteredQueryKnowledgeResource
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThan: query + 'z');

        filteredQueryCourses = filteredQueryCourses
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThan: query + 'z');
      }

      if (_selectedTags.isNotEmpty) {
        filteredQueryKnowledgeResource = filteredQueryKnowledgeResource
            .where('tags', arrayContainsAny: _selectedTags);
        filteredQueryCourses =
            filteredQueryCourses.where('tags', arrayContainsAny: _selectedTags);
      }

      _postsQuery = filteredQueryKnowledgeResource;
      _postsStream = _postsQuery.snapshots();

      _postsQueryCourses = filteredQueryCourses; // Add this line
      _postsStreamCourses = _postsQueryCourses.snapshots(); // Add this line
    });
  }



  void _viewPostDetails(BuildContext context, DocumentSnapshot post) {
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

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>
              ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)),
        );
        break;
    }
  }

  void _toggleBookmark(DocumentSnapshot post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bookmarkRef = FirebaseFirestore.instance.collection('bookmarks')
          .doc(user.uid)
          .collection('user_bookmarks')
          .doc(post.id);

      if (await bookmarkRef.get().then((doc) => doc.exists)) {
        bookmarkRef.delete();
      } else {
        bookmarkRef.set({
          'postId': post.id,
          'title': post['title'],
          // Add other necessary fields from the post
        });
      }
    }
  }


  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Filter by Tags'),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  children: widget.allTags.map((tag) {
                    bool isSelected = _selectedTags.contains(tag);
                    return TextButton(
                      onPressed: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTags.remove(tag);
                          } else {
                            _selectedTags.add(tag);
                          }
                        });
                        // Update isSelected value immediately
                        isSelected = !isSelected;
                        _searchPosts(_searchController.text); // Update posts based on selected tags
                      },
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          isSelected ? Colors.orange : Colors.grey[300]!,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
