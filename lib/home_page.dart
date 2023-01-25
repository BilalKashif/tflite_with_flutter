import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //--------------------------------------------------------------------------
  String imagePath = 'No Image';

  String result = '';

  //------Platform channel for native call-----------------------------------
  static const platform = MethodChannel('RunModel');

  //-----Call to native for running TF-lite model---------------------------
  Future<void> runModel(String path) async {
    try {
      var result =
          await platform.invokeMethod('objectDetection', {'path': path});
      /*
        ****NOTE*****
        var result is in the from of List<Map<String,String>>
        eg.
        [
          {
            'name' : 'Object Name',
            'confidence' : '90%',
            'boundingBox' : '10.0, 20.0, 30.0, 40.0',
            'width' : '100',
            'height' : '100' //Height and width of image
          },
          ....... and so on
        ]
       */

      getObjectsInfo(result);
    } on PlatformException catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF373737),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'TF-Lite Model with Flutter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            //---------For showing the selected or captured Image
            imagePath == 'No Image' ? noImage() : image(),

            //--------For showing the result from the model

            result == ''
                ? const SizedBox()
                : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      'Result: $result',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  pickImageFromGallery();
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateColor.resolveWith((states) => Colors.black),
                ),
                child: const Text(
                  'Select Image from gallery',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  pickImageFromCamera();
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateColor.resolveWith((states) => Colors.black),
                ),
                child: const Text(
                  'Select Image from camera',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //----------------------------------------------------------------------------

  void pickImageFromGallery() {
    final ImagePicker picker = ImagePicker();

    picker.pickImage(source: ImageSource.gallery).then((image) {
      setState(() {
        if (image != null) {
          imagePath = image.path;
          result = '';
          runModel(image.path);
        }
      });
    });
  }

  void pickImageFromCamera() {
    final ImagePicker picker = ImagePicker();

    picker
        .pickImage(source: ImageSource.camera, imageQuality: 50)
        .then((image) {
      setState(() {
        if (image != null) {
          imagePath = image.path;
          result = '';
          runModel(image.path);
        }
      });
    });
  }

  void getObjectsInfo(List<dynamic> result) {
    if (result.isEmpty) {
      setState(() {
        this.result = 'Not Found';
      });
    } else {
      result.forEach((element) {
        //*****Bounding Boxes********
        /*The bounding boxes are in order Left, Top, Right, Bottom
    Use this code to get the bounding boxes array and use them in given order

         var coordinates = element["boundingBox"]?.split(','); //List<String>
      For instance we want to get the left cordinate of bounding box then
          double left = double.parse(coordinates[0]);
      and so on...
    */
        setState(() {
          this.result =
              '${this.result} ${element['name']}(${element['confidence']})';
        });
      });
    }
  }

  Widget noImage() {
    return const Icon(
      Icons.image,
      color: Colors.grey,
      size: 200,
    );
  }

  Widget image() {
    return Expanded(
      // width: double.infinity,
      child: Image.file(
        File(imagePath),
      ),
    );
  }
}
