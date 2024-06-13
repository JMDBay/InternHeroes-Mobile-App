import 'dart:io';
import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AddPostCerts extends StatefulWidget {
  @override
  _AddPostCertPageState createState() => _AddPostCertPageState();
}

class _AddPostCertPageState extends State<AddPostCerts> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _learnController = TextEditingController();
  final TextEditingController _highlightsController = TextEditingController();
  final TextEditingController _forController = TextEditingController();
  final TextEditingController _prerequisitesController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _certificateController = TextEditingController();

  List<String> selectedTags = [];
  List<File> _images = [];

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

  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    fetchProfileImageUrl();
  }

  Future<void> fetchProfileImageUrl() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        profileImageUrl = (snapshot.data() as Map<String, dynamic>)['profileImageUrl'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Post'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => KnowledgeResource()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  profileImageUrl != null
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(profileImageUrl!),
                  )
                      : SizedBox(),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Course Title',
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 5, vertical: 24),
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TAGS',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          ...selectedTags.map((tag) => _buildTag(tag)),
                          GestureDetector(
                            onTap: _addNewTag,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.transparent),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Add tag',
                                      style: TextStyle(color: Colors.black)),
                                  SizedBox(width: 4),
                                  Icon(Icons.add),
                                ],
                              ),
                            ),
                          ),
                          if (selectedTags.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedTags.clear();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.transparent),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Clear',
                                        style: TextStyle(color: Colors.black)),
                                    SizedBox(width: 4),
                                    Icon(Icons.clear),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildTextFieldWithTitle('Course Description:', _descriptionController),
            SizedBox(height: 10),
            _buildTextFieldWithTitle('Requirements:', _requirementsController),
            SizedBox(height: 10),
            _buildTextFieldWithTitle('What will you learn:', _learnController),
            SizedBox(height: 10),
            _buildTextFieldWithTitle('Course highlights:', _highlightsController),
            SizedBox(height: 10),
            _buildTextFieldWithTitle('Who this course is for:', _forController),
            SizedBox(height: 10),
            _buildTextFieldWithTitle('Prerequisites:', _prerequisitesController),
            SizedBox(height: 10),
            _buildTextFieldWithTitle('Course fee:', _feeController),
            SizedBox(height: 10),
            _buildTextFieldWithTitle('Certificate:', _certificateController),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(
                    Icons.photo_library,
                    size: 30,
                  ),
                  color: Colors.yellow[800],
                  tooltip: 'Select Image',
                ),
                SizedBox(width: 10),
                IconButton(
                  onPressed: _addLink,
                  icon: Icon(
                    Icons.link,
                    size: 30,
                  ),
                  color: Colors.blue,
                  tooltip: 'Add Link',
                ),
                SizedBox(width: 10),
                IconButton(
                  onPressed: _addDocument,
                  icon: Icon(
                    Icons.insert_drive_file,
                    size: 30,
                  ),
                  color: Colors.green,
                  tooltip: 'Upload Document',
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildImagePreview(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => _addPost(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldWithTitle(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLines: null,
        ),
      ],
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        color: Colors.yellow[800],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_images.isNotEmpty) {
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _images.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Image.file(_images[index]),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _images.removeAt(index);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      return SizedBox();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage();

    setState(() {
      if (pickedImages != null) {
        for (var pickedImage in pickedImages) {
          _images.add(File(pickedImage.path!));
        }
      } else {
        print('No images selected.');
      }
    });
  }

  void _addLink() {
    showDialog(
      context: context,
      barrierDismissible: true, // Set to true to allow dismissing by tapping outside
      builder: (BuildContext context) {
        String link = '';
        return AlertDialog(
          title: Text('Add Link'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter the link:'),
                TextField(
                  onChanged: (value) {
                    link = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter link here',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (Uri.parse(link).isAbsolute) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link added: $link'),
                    ),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid link'),
                    ),
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }



  void _addDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document uploaded successfully'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No document selected'),
        ),
      );
    }
  }

  void _addPost(BuildContext context) async {
    String title = _titleController.text;
    String description = _descriptionController.text;
    String link = _linkController.text;
    String requirements = _requirementsController.text;
    String learn = _learnController.text;
    String highlights = _highlightsController.text;
    String forWhom = _forController.text;
    String prerequisites = _prerequisitesController.text;
    String fee = _feeController.text;
    String certificate = _certificateController.text;

    if (title.isEmpty || description.isEmpty || selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill up all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      String? userName = user.displayName;

      List<String?> imageUrls = [];
      for (File image in _images) {
        final imageStorageRef = FirebaseStorage.instance.ref().child('images').child('${DateTime.now()}.jpg');
        await imageStorageRef.putFile(image);
        final imageUrl = await imageStorageRef.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      await FirebaseFirestore.instance.collection('courses').add({
        'title': title,
        'description': description,
        'userId': userId,
        'userName': userName,
        'datePosted': Timestamp.now(),
        'tags': selectedTags,
        'imageUrls': imageUrls,
        'link': link,
        'requirements': requirements,
        'learn': learn,
        'highlights': highlights,
        'forWhom': forWhom,
        'prerequisites': prerequisites,
        'fee': fee,
        'certificate': certificate,
        'status': 'pending',
      });

      // Navigate back to the knowledge resource page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => KnowledgeResource()),
      );

    } else {
      print('User is not authenticated.');
    }
  }


  void _addNewTag() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newTag = '';
        return AlertDialog(
          title: Text('Add New Tag'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Choose from existing tags:'),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: allTags.map((tag) {
                      if (selectedTags.contains(tag)) {
                        return SizedBox();
                      } else {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTags.add(tag);
                            });
                          },
                          child: Chip(
                            label: Text(tag),
                            backgroundColor: Colors.yellow[800],
                            labelStyle: TextStyle(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.transparent),
                            ),
                          ),
                        );
                      }
                    }).toList(),
                  ),
                ),
                SizedBox(height: 70),
                Text('If not in the choices, add new:'),
                TextField(
                  onChanged: (value) {
                    newTag = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter tag name',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (selectedTags.any((tag) => tag.toLowerCase() == newTag.toLowerCase())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('This tag is already added'),
                    ),
                  );
                } else if (newTag.isNotEmpty) {
                  setState(() {
                    selectedTags.add(newTag);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  void _removeTag(String tag) {
    setState(() {
      selectedTags.remove(tag);
    });
  }
}
