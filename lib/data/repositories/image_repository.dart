// TODO: Add an AppGlideModule to make the thumbnails load faster when opening the image picker
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:path/path.dart' as path;

import 'package:aegis_reforged/data/services/gemini_service.dart';
import 'package:aegis_reforged/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:native_exif/native_exif.dart';

final imageSaver = ImageGallerySaver();

class GeneratedMetadata {
  String filename;
  String description;
  List<String> tags;

  GeneratedMetadata(this.filename, this.description, this.tags);

  // Factory constructor for creating an instance from a Map
  factory GeneratedMetadata.fromMap(Map<String, dynamic> map) {
    // Safely retrieve and cast, or use defensive programming
    final String filename = map["filename"] as String;
    final String description = map["desc"] as String;
    
    // Handle the List: cast the outer list and then map the elements to strings
    final List<dynamic> rawTagList = map["tags"] as List<dynamic>;
    // If an element isn't a string, this will throw a runtime error, but this won't be an issue for us. 
    final List<String> validatedTagList = rawTagList.cast<String>().toList(); 
    
    return GeneratedMetadata(filename, description, validatedTagList);
  }
}

class ImageRepository {
  ImageRepository({
    required GeminiService gemini,
  }) : _gemini = gemini;

  final GeminiService _gemini;


  Future<Result<String>> editMetadataAndSave(AssetEntity img, GeneratedMetadata metadata) async {
    try {
      // This creates a copy of the file in the temporary storage of this app
      // We edit this temporary copy, then save it as a permanent copy using photo_manager
      File? file = await img.originFile;

      if (file != null) {
        // Edit metadata
        final exif = await Exif.fromPath(file.path);
        print("Still here");
        await exif.writeAttributes({
          // Standard Description
          // 'ImageDescription': metadata.description,
          // NOTE: Android and IOS don't support the Image Description field :(

          // The "Universal" place to put data on mobile
          // We might change this to be the description, rather than tags
          'UserComment': metadata.tags.join(", "),

          // The "Software" field is used to indicate app origin - this allows us to identify whether
          // a photo has already been tagged via Aegis
          'Software': 'Aegis',
        });
        await exif.close();
        // Edit filename
        // var dir = path.dirname(file.path);
        // var newPath = path.join(dir, metadata.filename);
        // File newFile = await file.rename(newPath);
        // Now we need to return the edited File object

        // 4. Save the Modified File as a NEW Asset in the Gallery
        // We don't need to ask for permission, because to get here you need to pass the
        // permission check in photo_upload_screen.dart
        await imageSaver.saveImage(await file.readAsBytes());
        // final AssetEntity newEntity = await PhotoManager.editor.saveImageWithPath(
        //   file.path,
        //   // file.readAsBytesSync(),
        //   // filename: metadata.filename,
        //   title: "${metadata.filename}.jpg",
        //   desc: metadata.description,
        //   relativePath: img.relativePath
        // );
        // We don't do anything with this. It should save the file, if not, might need to do some messing around with temporary directories
        // We just return it rn because eh fuck it
        return Result.ok("");
      } else {
        print("TEMP LOG: Failed to get originFile for image with id ${img.id} in editMetadata()");
        throw FileSystemException("Failed to get originFile for image with id ${img.id} in editMetadata()");
      }

    }  on FileSystemException catch (e) {
      return Result.error(e);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  GeneratedMetadata geminiResponseToMetadata(Candidates response) {
    var geminiJson = response.output;
    if (geminiJson != null) {
      Map<String, dynamic> decodedResponse = jsonDecode(geminiJson);
      print("filename: ${decodedResponse["filename"]}");
      print("description: ${decodedResponse["desc"]}");
      for (var tag in decodedResponse["tags"]) {
        print("Tag: $tag");
      }
      return GeneratedMetadata.fromMap(decodedResponse);
    } else {
      throw Exception("Gemini response is empty");
    }
  }

  Stream<int> sendImagesToGemini(List<AssetEntity> imgList) async* {
    // Construct a list of just the bytes. We may also do some other things will the rest of 
    // the info here in the future, such as checking the filename and not passing the image
    // to Gemini if it is already something that appears human created.
    for (final (index, img) in imgList.indexed) {
      Exception? geminiError;
      final Uint8List? bytes = await img.originBytes;
      // TODO: Get the file extension and save it for appending to the generated filename later
      if (bytes != null) {
        final result = _gemini.generateImageMetadata(bytes);
        switch (result) {
          case Ok<Future<Candidates?>>():
            // Gemini response secured successfully
            Candidates? geminiResponse = await result.value;
            if (geminiResponse != null) {
              try {
                print(geminiResponse.output);
                GeneratedMetadata metadata = geminiResponseToMetadata(geminiResponse);
                print("Tags: ${metadata.tags}");
                await editMetadataAndSave(img, metadata);
              } on StateError catch (e) {
                print("GEMINI STATEERROR: $e");
              }
              // Pass the number of processed images back to the viewmodel
              yield index+1;
            }
          case Error<Future<Candidates?>>():
            geminiError = result.error;
            // TODO: Pass up error to viewmodel, and log error
        }
      } else {
        print("TEMP LOG: img.originBytes failed for asset with ID: ${img.id}");
      }
    } 



  }

}
