import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
class AdditionalInformationPage extends StatefulWidget {
  const AdditionalInformationPage({Key? key}) : super(key: key);

  @override
  _AdditionalInformationPageState createState() =>
      _AdditionalInformationPageState();
}

class _AdditionalInformationPageState
    extends State<AdditionalInformationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TextEditingController _phoneNumberController = TextEditingController();
  DateTime? _selectedDate;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _prepopulateTextFields();
  }

  void _prepopulateTextFields() async {
    // Get current user
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Fetch user data from Firestore
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userData.exists) {
          Map<String, dynamic>? userDataMap =
          userData.data() as Map<String, dynamic>?;

          setState(() {
            _phoneNumberController.text = userDataMap?['phoneNumber'] ?? '';
            // Check if birthday exists in user data
            if (userDataMap?['birthday'] != null) {
              _selectedDate = DateTime.parse(userDataMap?['birthday']);
            }
          });
        } else {
          print('Document does not exist in Firestore.');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Widget _buildFormContainer({
    required TextEditingController controller,
    required String hintText,
    required bool isPasswordField,
    TextInputType keyboardType = TextInputType.text,
    String? hintTextSuffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText + (hintTextSuffix ?? ""),
      ),
      obscureText: isPasswordField,
      keyboardType: keyboardType,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveAdditionalInformation() async {
    // Check if all fields are filled
    if (_phoneNumberController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields'),
        backgroundColor: Colors.yellow[800],
      ));
      return;
    }

    setState(() {
      isSaving = true;
    });

    String phoneNumber = _phoneNumberController.text;
    String birthday = DateFormat('yyyy-MM-dd').format(_selectedDate!); // Convert date to ISO8601 format

    // Get current user
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Update additional information in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          "phoneNumber": phoneNumber,
          "birthday": birthday,

        });

        setState(() {
          isSaving = false;
        });

        // Navigate to the professional information page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfessionalInformationPage()),
        );
      } catch (e) {
        print('Error saving additional information: $e');
        setState(() {
          isSaving = false;
        });
      }
    } else {
      print("User not found");
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Additional Information'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            _buildFormContainer(
              controller: _phoneNumberController,
              hintText: "Phone Number",
              isPasswordField: false,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: () {
                _selectDate(context);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Birthday',
                  hintText: 'Select Birthday',
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.toLocal()}'.split(' ')[0]
                          : 'Select Birthday',
                    ),
                    Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: Container(
                width: 350,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    _saveAdditionalInformation(); // Save additional information before navigating
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfessionalInformationPage extends StatefulWidget {
  const ProfessionalInformationPage({Key? key}) : super(key: key);

  @override
  _ProfessionalInformationPageState createState() =>
      _ProfessionalInformationPageState();
}

class _ProfessionalInformationPageState
    extends State<ProfessionalInformationPage> {
  final TextEditingController _universityController =
  TextEditingController();
  final TextEditingController _yearAndCourseController =
  TextEditingController();
  final TextEditingController _ojtCoordinatorEmailController =
  TextEditingController();
  final TextEditingController _requiredHoursController =
  TextEditingController();
  final TextEditingController _careerPathController =
  TextEditingController();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _prepopulateProfessionalInformationFields();
  }

  void _prepopulateProfessionalInformationFields() async {
    // Get current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Fetch professional information data from Firestore
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userData.exists) {
          Map<String, dynamic>? userDataMap =
          userData.data() as Map<String, dynamic>?;

          setState(() {
            _universityController.text = userDataMap?['university'] ?? '';
            _yearAndCourseController.text =
                userDataMap?['yearAndCourse'] ?? '';
            _ojtCoordinatorEmailController.text =
                userDataMap?['ojtCoordinatorEmail'] ?? '';
            _requiredHoursController.text = userDataMap?['requiredHours'] ?? '';
            _careerPathController.text = userDataMap?['careerPath'] ?? '';
          });
        } else {

          print('Document does not exist in Firestore.');
        }
      } catch (e) {
        print('Error fetching professional information data: $e');
      }
    }
  }

  Widget _buildFormContainer({
    required TextEditingController controller,
    required String hintText,
    required bool isPasswordField,
    TextInputType keyboardType = TextInputType.text,
    String? hintTextSuffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText + (hintTextSuffix != null ? hintTextSuffix : ""),
      ),
      obscureText: isPasswordField,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professional Information'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            _buildFormContainer(
              controller: _universityController,
              hintText: "University",
              isPasswordField: false,
            ),
            SizedBox(height: 10),
            _buildFormContainer(
              controller: _yearAndCourseController,
              hintText: "Year and Course",
              isPasswordField: false,
            ),
            SizedBox(height: 10),
            _buildFormContainer(
              controller: _ojtCoordinatorEmailController,
              hintText: "OJT Coordinator Email",
              isPasswordField: false,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            _buildFormContainer(
              controller: _requiredHoursController,
              hintText: "Required Hours",
              isPasswordField: false,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            _buildFormContainer(
              controller: _careerPathController,
              hintText: "Career Path",
              isPasswordField: false,
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_validateFields()) {
                    _saveProfessionalInformation();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSaving
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateFields() {
    if (_universityController.text.isEmpty ||
        _yearAndCourseController.text.isEmpty ||
        _ojtCoordinatorEmailController.text.isEmpty ||
        _requiredHoursController.text.isEmpty ||
        _careerPathController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields'),
        backgroundColor: Colors.yellow[800],
      ));

      return false;
    }
    return true;
  }

  void _saveProfessionalInformation() async {
    setState(() {
      isSaving = true;
    });

    String university = _universityController.text;
    String yearAndCourse = _yearAndCourseController.text;
    String ojtCoordinatorEmail = _ojtCoordinatorEmailController.text;
    String requiredHours = _requiredHoursController.text;
    String careerPath = _careerPathController.text;

    // Get current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Update professional information in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          "university": university,
          "yearAndCourse": yearAndCourse,
          "ojtCoordinatorEmail": ojtCoordinatorEmail,
          "requiredHours": requiredHours,
          "careerPath": careerPath,
        });

        setState(() {
          isSaving = false;
        });

        // Navigate back to the additional information page
        Navigator.pop(context);

        // Proceed to the home screen
        Navigator.pushReplacementNamed(context, "/home");
      } catch (e) {
        print('Error saving professional information: $e');
        setState(() {
          isSaving = false;
        });
      }
    } else {
      print("User not found");
      setState(() {
        isSaving = false;
      });
    }
  }
}
