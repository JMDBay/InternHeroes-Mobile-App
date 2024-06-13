import 'package:InternHeroes/features/user_auth/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showAllCards = false;

  @override
  Widget build(BuildContext context) {
    String? displayName = FirebaseAuth.instance.currentUser?.displayName;

    return WillPopScope(
      onWillPop: () async {
        return false; // Disable back button
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.0),
          child: AppBar(
            title: Text(
              'Hi, ${displayName ?? 'User'}!',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) =>
                      ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)),
                );
              },
            ),
            backgroundColor: Colors.orange,
            automaticallyImplyLeading: false, // Remove back button
            centerTitle: true, // Center-align the title
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 24, // Increased font size
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Changed text color
                      ),
                    ),
                    SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        int _totalInterns = snapshot.data!.size;
                        String totalInternsText = 'Total Interns: $_totalInterns';

                        return Text(
                          totalInternsText,
                          style: TextStyle(
                            fontSize: 20, // Increased font size
                            color: Colors.black, // Changed text color
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildUserCard('Flutter', Icons.account_circle, 'Flutter', 0),
                        SizedBox(width: 16),
                        _buildUserCard('Webflow', Icons.account_circle, 'Webflow', 1),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildUserCard('Vercel', Icons.account_circle, 'Vercel', 2),
                        SizedBox(width: 16),
                        _buildUserCard('UI/UX', Icons.account_circle, 'UI/UX', 3),
                      ],
                    ),
                    SizedBox(height: 16),
                    _showAllCards
                        ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildUserCard('Programming', Icons.account_circle, 'Programming', 4),
                            SizedBox(width: 16),
                            _buildUserCard('Database Manager', Icons.account_circle, 'Database Manager', 5),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildUserCard('System Admin', Icons.account_circle, 'System Administrator', 6),
                            SizedBox(width: 16),
                            _buildUserCard('Quality Assurance', Icons.account_circle, 'Quality Assurance', 7),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildUserCard('Service Assurance', Icons.account_circle, 'Service Assurance', 8),
                          ],
                        ),
                      ],
                    )
                        : SizedBox(),
                    SizedBox(height: 16),
                    _showAllCards
                        ? ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showAllCards = false;
                        });
                      },
                      child: Text('See less'),
                    )
                        : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showAllCards = true;
                        });
                      },
                      child: Text('See more'),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0), // Add a margin between the button and the text
                      child: Text(
                        'Resources',
                        style: TextStyle(
                          fontSize: 24, // Increased font size
                          color: Colors.black, // Changed text color
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildResourceCard('Knowledge Resources', Icons.library_books, 'knowledge_resource', 0),
                          SizedBox(width: 16),
                          _buildResourceCard('Courses & Certificates', Icons.school, 'courses', 1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(String name, IconData icon, String careerPath, int index) {
    if (!_showAllCards && index > 3) {
      return SizedBox(); // Hide the card if not showing all cards and index is greater than 3
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        width: 145, // Increased width
        height: 145, // Increased height
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 4),
            FutureBuilder<int>(
              future: _getUserCount(careerPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                return Text(
                  '${snapshot.data ?? 0}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(String name, IconData icon, String collection, int index) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        width: 145,
        height: 145,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center, // Center-align the text
              ),
            ),
            SizedBox(height: 4),
            FutureBuilder<int>(
              future: _getResourceCount(collection),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                return Text(
                  '${snapshot.data ?? 0}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getUserCount(String careerPath) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where('careerPath', arrayContains: careerPath).get();
    return querySnapshot.size;
  }

  Future<int> _getResourceCount(String collection) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection(collection).get();
    return querySnapshot.size;
  }
}

void main() {
  runApp(MaterialApp(
    home: DashboardPage(),
  ));
}
