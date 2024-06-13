import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/image_slider.dart';

class PostDetailsCertsPage extends StatelessWidget {
  final DocumentSnapshot post;

  const PostDetailsCertsPage({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['title'] ?? 'Title not available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: (post['tags'] as List<dynamic>).map<Widget>((tag) {
                  return Material(
                    color: Colors.yellow[800],
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10, // Set font size to 10
                          color: Colors.white, // Set text color to white
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text(
                post['description'] ?? 'Description not available',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 20),
              // Display image slider if available
              if (post['imageUrls'] != null && (post['imageUrls'] as List).isNotEmpty)
                ImageSlider(imageUrls: List<String>.from(post['imageUrls'])),
              SizedBox(height: 20),
              _buildField('Requirements', post['requirements']),
              _buildField('What will you learn', post['learn']),
              _buildField('Course highlights', post['highlights']),
              _buildField('Who this course is for', post['forWhom']),
              _buildField('Prerequisites', post['prerequisites']),
              _buildField('Course fee', post['fee']),
              _buildField('Certificate', post['certificate']),
              SizedBox(height: 20),
              FutureBuilder(
                future: _getPostUserName(post),
                builder: (context, AsyncSnapshot<String> userNameSnapshot) {
                  if (userNameSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (userNameSnapshot.hasData) {
                    return Text(
                      'Posted by: ${userNameSnapshot.data}',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  } else {
                    return Text(
                      'Posted by: Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Navigate back to the previous screen
                    },
                    child: Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String title, String? value) {
    return ExpansionTile(
      title: Text(
        '$title:',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            value ?? 'Not specified',
            style: TextStyle(
              fontSize: 16,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }



  Future<String> _getPostUserName(DocumentSnapshot post) async {
    final userId = post['userId'];
    final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot['name'];
  }
}


