import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:aegis_reforged/data/services/gemini_service.dart';
import 'package:aegis_reforged/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:native_exif/native_exif.dart';


class GeneratedMetadata {
  String filename;
  String description;
  String tags;

  GeneratedMetadata(this.filename, this.description, this.tags);
}

class ImageRepository {
  ImageRepository({
    required GeminiService gemini,
  }) : _gemini = gemini;

  final GeminiService _gemini;


  Future<Result<AssetEntity>> editMetadataAndSave(AssetEntity img, GeneratedMetadata metadata) async {
    try {
      // This creates a copy of the file in the temporary storage of this app
      // We edit this temporary copy, then save it as a permanent copy using photo_manager
      File? file = await img.originFile;

      if (file != null) {
        // Edit metadata
        final exif = await Exif.fromPath(file.path);
        await exif.writeAttributes({
          // Standard Description
          // 'ImageDescription': metadata.description,
          // NOTE: Android and IOS don't support the Image Description field :(

          // The "Universal" place to put data on mobile
          // We might change this to be the description, rather than tags
          'UserComment': metadata.tags,

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
        final AssetEntity? newEntity = await PhotoManager.editor.saveImage(
          file.readAsBytesSync(),
          filename: metadata.filename,
          title: metadata.filename
        );
        // We don't do anything with this. It should save the file, if not, might need to do some messing around with temporary directories
        // We just return it rn because eh fuck it
        if (newEntity != null) {
          return Result.ok(newEntity);
        } else {
          print("TEMP LOG: PhotoManager.editor.saveImage() returned null, image ${metadata.filename} may not have been saved properly");
          throw FileSystemException("PhotoManager.editor.saveImage() returned null, image ${metadata.filename} may not have been saved properly");
        }
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

  // TODO: Fix Json string conversion
  // GeneratedMetadata geminiResponseToMetadata(Candidates response) {
  //   var geminiJson = response.content;
  //   if (geminiJson != null) {
  //     Map decodedResponse = jsonDecode(geminiJson.parts.first.toString());
  //     return GeneratedMetadata(decodedResponse["filename"], decodedResponse["description"], decodedResponse["tags"]);
  //
  //   } else {
  //     throw Exception("Gemini response is empty");
  //   }
  // }

  Stream<int> sendImagesToGemini(List<AssetEntity> imgList) async* {
    // Construct a list of just the bytes. We may also do some other things will the rest of 
    // the info here in the future, such as checking the filename and not passing the image
    // to Gemini if it is already something that appears human created.
    for (final (index, img) in imgList.indexed) {
      Exception? geminiError;
      final Uint8List? bytes = await img.originBytes;
      if (bytes != null) {
        final result = _gemini.generateImageMetadata(bytes);
        switch (result) {
          case Ok<Future<Candidates?>>():
            // Gemini response secured successfully
            Candidates? geminiResponse = await result.value;
            if (geminiResponse != null) {
              // HACK: temporary commenting out for testing
              // GeneratedMetadata metadata = geminiResponseToMetadata(geminiResponse);
              // await editMetadataAndSave(img, metadata);
              try {
                print(geminiResponse.output);
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
