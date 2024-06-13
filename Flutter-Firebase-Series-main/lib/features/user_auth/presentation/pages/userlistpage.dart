import 'package:InternHeroes/features/user_auth/presentation/pages/ChooseTypePage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/chat_page.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/calendar.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/bottom_navbar.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late TextEditingController _searchController;
  late Stream<QuerySnapshot> _usersStream;
  bool _isSearching = false;
  late String _selectedCareerPath = 'All'; // Default value

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Chats',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight + 48), // Added height for tabs
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search for users...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.search),
                                onPressed: () {
                                  _search(_searchController.text);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8), // Add some space between the search bar and filter icon
                      IconButton(
                        icon: Icon(Icons.filter_list),
                        onPressed: () {
                          _showFilterDialog();
                        },
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(text: 'Interns'),
                    Tab(text: 'Admins'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildInternsList(),
            _buildAdminsList(),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: 1,
          onItemTapped: (index) {
            _handleNavigation(context, index);
          },
        ),
      ),
    );
  }

  Widget _buildInternsList() {
    return StreamBuilder(
      stream: _usersStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No interns available'),
          );
        } else {
          return _isSearching
              ? _buildSearchResults(snapshot.data!.docs)
              : _buildUserList(snapshot.data!.docs);
        }
      },
    );
  }

  Widget _buildAdminsList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('admin').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No admins available'),
          );
        } else {
          return _isSearching
              ? _buildSearchResults(snapshot.data!.docs)
              : _buildAdmins(snapshot.data!.docs);
        }
      },
    );
  }

  Widget _buildAdmins(List<DocumentSnapshot> docs) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var admin = docs[index];
        String fullName = '${admin['firstName']} ${admin['lastName']}';
        return ListTile(
          title: Text(fullName),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  recipientId: admin.id,
                  recipientName: fullName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserList(List<DocumentSnapshot> docs) {
    // Filter users by career path if a specific career path is selected
    if (_selectedCareerPath != 'All') {
      docs = docs.where((doc) {
        List<dynamic>? careerPathList = doc['careerPath'];
        return careerPathList != null && careerPathList.contains(_selectedCareerPath);
      }).toList();
    }

    // Sort and group users as before
    docs.sort((a, b) =>
        (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
    Map<String, List<DocumentSnapshot>> groupedUsers = {};
    docs.forEach((doc) {
      String firstLetter = (doc['name'] as String).substring(0, 1).toUpperCase();
      if (!groupedUsers.containsKey(firstLetter)) {
        groupedUsers[firstLetter] = [];
      }
      groupedUsers[firstLetter]!.add(doc);
    });

    // Generate the ListView with separators
    return ListView.builder(
      itemCount: groupedUsers.length * 2 - 1,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          return Divider();
        }
        final int itemIndex = index ~/ 2;
        final String letter = groupedUsers.keys.elementAt(itemIndex);
        final List<DocumentSnapshot> users = groupedUsers[letter]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(letter, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                var user = users[index];
                String? profileImageUrl = user['profileImageUrl'];

                List<dynamic>? careerPathList = user['careerPath'];
                String careerPath = careerPathList != null ? careerPathList.join(', ') : 'Career path not available';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : AssetImage('assets/superhero.jpg') as ImageProvider<Object>,
                  ),
                  title: Text(user['name'] ?? 'Name not available'),
                  subtitle: Text(careerPath),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          recipientId: user.id,
                          recipientName: user['name'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(List<DocumentSnapshot> docs) {
    // Implement your search logic here
    // For example, you can filter the docs based on the search query
    List<DocumentSnapshot> filteredUsers = docs.where((doc) {
      String name = doc['name'] as String;
      return name.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        var user = filteredUsers[index];
        String? profileImageUrl = user['profileImageUrl'];

        List<dynamic>? careerPathList = user['careerPath'];
        String careerPath = careerPathList != null ? careerPathList.join(', ') : 'Career path not available';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl)
                : AssetImage('assets/superhero.jpg') as ImageProvider<Object>,
          ),
          title: Text(user['name'] ?? 'Name not available'),
          subtitle: Text(careerPath),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  recipientId: user.id,
                  recipientName: user['name'],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Career Path'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCareerPathFilterItem('All'), // Default option
                _buildCareerPathFilterItem('UI/UX'),
                _buildCareerPathFilterItem('Vercel'),
                _buildCareerPathFilterItem('Webflow'),
                _buildCareerPathFilterItem('Flutter'),
                _buildCareerPathFilterItem('Programming'),
                _buildCareerPathFilterItem('Database Manager'),
                _buildCareerPathFilterItem('System Administrator'),
                _buildCareerPathFilterItem('Quality Assurance'),
                _buildCareerPathFilterItem('Service Assurance'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCareerPathFilterItem(String careerPath) {
    return ListTile(
      title: Text(careerPath),
      onTap: () {
        Navigator.pop(context);
        _filterByCareerPath(careerPath);
      },
    );
  }

  void _filterByCareerPath(String careerPath) {
    setState(() {
      _selectedCareerPath = careerPath;
      if (careerPath == 'All') {
        _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
      } else {
        _usersStream = FirebaseFirestore.instance
            .collection('users')
            .where('careerPath', arrayContains: careerPath)
            .snapshots();
      }
    });
  }

  void _search(String value) {
    setState(() {
      if (value.isEmpty) {
        _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
      } else {
        _usersStream = FirebaseFirestore.instance
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: value)
            .snapshots();
      }
    });
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => KnowledgeResource()),
        );
        break;
      case 1:
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
          MaterialPageRoute(
            builder: (context) => ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid),
          ),
        );
        break;
    }
  }
}
