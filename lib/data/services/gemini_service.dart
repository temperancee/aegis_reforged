// TODO: We are curently using the flutter_gemini plugin, which lacks features. In the future
//       we should move to using the firebase_ai plugin instead. 

import 'dart:typed_data';
import 'package:aegis_reforged/utils/result.dart';
import 'package:flutter_gemini/flutter_gemini.dart';



class GeminiService {
  final Gemini _client = Gemini.instance;

  final String prompt = "For each image passed, please provide a short description (variable name 'desc'), 5 one-word tags (variable name 'tags'), and a suitable filename (variable name 'filename'), which should be two words formatted in snake_case. Please also assign each image a number (variable name 'id'), based on the order in which they are passed (so the first image is image 1, the second is 2, and so on). Please return this data in JSON format.";

  Result<Future<Candidates?>> generateImageMetadata(Uint8List imgBytes) {
    try {
      // Return Gemini's response
      return Result.ok(_client.prompt(
        parts: [
          Part.bytes(imgBytes),
          Part.text(prompt),
        ],
        model: "gemini-1.5-flash",
      ));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}



// .listen((value) {
//   print(value?.output ?? "No response from Gemini");
  /* TODO: In here, we need to write metadata to the images as they come in
   * We also need to display a progress bar while this is happening, and allow for the 
   * rest of the app to be used in the meantime
   * Since so much stuff is going on in here, and the inference will probably take a while for large
   * albums of photos, we might have to put this function inside the page widget after all
   * Do some research on common flutter program structures to find out.
   */

  /* We want this to send the responses to a repository where they will be
   * processed (i.e. image metadata will be updated, and a service interacting
   * with the filesystem will be called, and a count of no. of processed 
   * images will be passed back to the view)
   */
// });

