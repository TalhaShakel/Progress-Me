import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Application',
      theme: ThemeData(
        primaryColor: Colors.blue.shade900,
        accentColor: Colors.blue.shade400,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  // String _fullName = "";
  File? _profilePhotoFile;
  File? _cvFile;

  var name = TextEditingController();

  String? _validateUploadCV(File? file) {
    if (file == null) {
      return 'Please upload your CV';
    }
    if (!file.path.endsWith('.pdf')) {
      return 'Invalid file format. Please upload a PDF file.';
    }
    return null;
  }

  String? _validateUploadPhoto(File? file) {
    if (file == null) {
      return 'Please upload your profile photo';
    }
    if (!['jpg', 'jpeg', 'png'].contains(file.path.split('.').last)) {
      return 'Invalid file format. Please upload a JPG, JPEG, or PNG file.';
    }
    return null;
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final pickedFile =
          await ImagePicker().getImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profilePhotoFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking profile photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking profile photo. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        setState(() {
          _cvFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      print('Error picking CV: $e');
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking CV.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isSubmitting = false;

  void _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    if (name.text.toString() != "" &&
        _cvFile != null &&
        _profilePhotoFile != null) {
      // Upload the data to Firestore
      try {
        await FirebaseFirestore.instance.collection('applications').add({
          'fullName': name.text.toString(),
          'cvUrl': _cvFile != null ? await uploadFile(_cvFile!) : null,
          'profilePhotoUrl': _profilePhotoFile != null
              ? await uploadFile(_profilePhotoFile!)
              : null,
        });
      } catch (e) {
        print('Error uploading data to Firestore: $e');
        Get.snackbar(
          'Error uploading data to Firestore',
          'Please try again later.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );

        setState(() {
          _isSubmitting = false;
        });

        return;
      }

      Get.snackbar(
        'Data uploaded to Firestore',
        'Thank you for your application!',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.greenAccent,
        colorText: Colors.black,
        borderRadius: 16.0,
        margin: const EdgeInsets.all(16.0),
        isDismissible: true,
        forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
        reverseAnimationCurve: Curves.fastLinearToSlowEaseIn.flipped,
        animationDuration: const Duration(milliseconds: 500),
        icon: const Icon(Icons.check_circle),
        shouldIconPulse: true,
        leftBarIndicatorColor: Colors.green,
      );
    } else {
      Get.snackbar(
        'Form not valid',
        'Please fill in all required fields.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  Widget _buildSubmitButton() {
    return _isSubmitting
        ? CircularProgressIndicator()
        : ElevatedButton(
            child: Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              primary: Color.fromRGBO(32, 23, 23, 1),
              onPrimary: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            onPressed: _submitForm,
          );
  }

  Future<String> uploadFile(File file) async {
    try {
      final reference =
          FirebaseStorage.instance.ref('uploads/${file.path.split('/').last}');
      final uploadTask = reference.putFile(file);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      print('Firebase storage error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file. Please try again later.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    } catch (e) {
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file. Please try again later.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3A40CF),
// appBar: AppBar(
// title: Text('My Application'),
// ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  _pickProfilePhoto();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey,
                          width: 2,
                        ),
                        image: _profilePhotoFile != null
                            ? DecorationImage(
                                image: FileImage(_profilePhotoFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profilePhotoFile == null
                          ? Icon(
                              Icons.add_a_photo,
                              size: 50,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 46),
// Text(
// 'Full Name',
// style: Theme.of(context).textTheme.headline6!.copyWith(
// color: Theme.of(context).accentColor,
// ),
// ),
// const SizedBox(height: 8),
              TextFormField(
                controller: name,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
                // onSaved: (value) {
                //   print(value);
                //   _fullName = value!;
                // },
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Upload CV',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Icon(Icons.description),
                ),
                controller: TextEditingController(
                  text: _cvFile != null ? _cvFile!.path.split('/').last : '',
                ),
                onTap: _pickCV,
                validator: (value) {
                  return _validateUploadCV(_cvFile);
                },
              ),
              const SizedBox(height: 32),
              Center(
                child: Center(
                  child: _buildSubmitButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final _formKey = GlobalKey<FormState>();

//   String? _fullName;
//   File? _profilePhotoFile;
//   File? _cvFile;
//   Future<void> _pickProfilePhoto() async {
//     try {
//       final pickedFile =
//           await ImagePicker().getImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         setState(() {
//           _profilePhotoFile = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       print('Error picking profile photo: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error picking profile photo. Please try again.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Future<void> _pickCV() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//       );
//       if (result != null) {
//         setState(() {
//           _cvFile = File(result.files.single.path!);
//         });
//       }
//     } catch (e) {
//       print('Error picking CV: $e');
//       // Show an error message to the user
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error picking CV.'),
//           duration: Duration(seconds: 3),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _submitForm() async {
//     if (_formKey.currentState != null && _formKey.currentState!.validate()) {
//       _formKey.currentState!.save();

//       // Upload the data to Firestore
//       try {
//         await FirebaseFirestore.instance.collection('applications').add({
//           'fullName': _fullName,
//           'cvUrl': _cvFile != null ? await uploadFile(_cvFile!) : null,
//           'profilePhotoUrl': _profilePhotoFile != null
//               ? await uploadFile(_profilePhotoFile!)
//               : null,
//         });
//       } catch (e) {
//         print('Error uploading data to Firestore: $e');
//         Get.snackbar(
//           'Error uploading data to Firestore',
//           'Please try again later.',
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//         return;
//       }

//       Get.snackbar(
//         'Data uploaded to Firestore',
//         'Thank you for your application!',
//         duration: const Duration(seconds: 3),
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.greenAccent,
//         colorText: Colors.black,
//         borderRadius: 16.0,
//         margin: const EdgeInsets.all(16.0),
//         isDismissible: true,
//         forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
//         reverseAnimationCurve: Curves.fastLinearToSlowEaseIn.flipped,
//         animationDuration: const Duration(milliseconds: 500),
//         icon: const Icon(Icons.check_circle),
//         shouldIconPulse: true,
//         leftBarIndicatorColor: Colors.green,
//       );
//     }
//   }

//   Future<String> uploadFile(File file) async {
//     try {
//       final reference =
//           FirebaseStorage.instance.ref('uploads/${file.path.split('/').last}');
//       final uploadTask = reference.putFile(file);
//       final snapshot = await uploadTask;
//       final url = await snapshot.ref.getDownloadURL();
//       return url;
//     } on FirebaseException catch (e) {
//       print('Firebase storage error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error uploading file. Please try again later.'),
//           duration: Duration(seconds: 3),
//           backgroundColor: Colors.red,
//         ),
//       );
//       rethrow;
//     } catch (e) {
//       print('Error uploading file: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error uploading file. Please try again later.'),
//           duration: Duration(seconds: 3),
//           backgroundColor: Colors.red,
//         ),
//       );
//       rethrow;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF3A40CF),
//       // appBar: AppBar(
//       //   title: Text('My Application'),
//       // ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   _pickProfilePhoto();
//                 },
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: 140,
//                       height: 180,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: Colors.grey,
//                           width: 2,
//                         ),
//                         image: _profilePhotoFile != null
//                             ? DecorationImage(
//                                 image: FileImage(_profilePhotoFile!),
//                                 fit: BoxFit.cover,
//                               )
//                             : null,
//                       ),
//                       child: _profilePhotoFile == null
//                           ? Icon(
//                               Icons.add_a_photo,
//                               size: 50,
//                             )
//                           : null,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 46),
//               // Text(
//               //   'Full Name',
//               //   style: Theme.of(context).textTheme.headline6!.copyWith(
//               //         color: Theme.of(context).accentColor,
//               //       ),
//               // ),
//               // const SizedBox(height: 8),
//               TextFormField(
//                 decoration: InputDecoration(
//                   hintText: 'Enter your full name',
//                   filled: true,
//                   fillColor: Colors.grey.shade200,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value!.isEmpty) {
//                     return 'Please enter your full name';
//                   }
//                   return null;
//                 },
//                 onSaved: (value) {
//                   _fullName = value;
//                 },
//               ),
//               const SizedBox(height: 16),
//               // Text(
//               //   'Upload CV',
//               //   style: Theme.of(context).textTheme.headline6!.copyWith(
//               //         color: Theme.of(context).accentColor,
//               //       ),
//               // ),
//               // const SizedBox(height: 8),
//               TextFormField(
//                 readOnly: true,
//                 decoration: InputDecoration(
//                   hintText: 'Upload CV',
//                   filled: true,
//                   fillColor: Colors.grey.shade200,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: BorderSide.none,
//                   ),
//                   suffixIcon: Icon(Icons.description),
//                 ),
//                 controller: TextEditingController(
//                   text: _cvFile != null ? _cvFile!.path.split('/').last : '',
//                 ),
//                 onTap: _pickCV,
//               ),
//               const SizedBox(height: 32),
//               Center(
//                 child: ElevatedButton(
//                   child: Text(
//                     'Submit',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     primary: Color.fromRGBO(32, 23, 23, 1),
//                     onPrimary: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                   ),
//                   onPressed: _submitForm,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
