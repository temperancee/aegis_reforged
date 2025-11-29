
import 'package:aegis_reforged/data/repositories/image_repository.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoUploadViewModel extends ChangeNotifier {
  PhotoUploadViewModel({
    required ImageRepository imageRepository,
  }): _imageRepository = imageRepository;

  final ImageRepository _imageRepository;

  // State variables for the view
  int _totalImgCount = 0;
  int _processedImgCount = 0;
  bool _isProcessing = false;

  // Getters - the view uses these to access the internal variables (idk why we don't just make them
  // not hidden)
  int get processedImgCount => _processedImgCount;
  int get totalImgCount => _totalImgCount;
  bool get isProcessing => _isProcessing;

  // For the progress bar
  double get progressPercentage {
    if (_totalImgCount == 0) return 0.0;
    return _processedImgCount / _totalImgCount;
  }

  
  void processImages(List<AssetEntity> imgList) {
      // This callback should send the images to Gemini via a service fn.
      // a service fn., save them, and then pass a stream(?) of integers counting the
      // number of processed images back to the UI to be used in the loading widget

      // Set initial values for state variables 
      _totalImgCount = imgList.length;
      _isProcessing = true;
      _processedImgCount = 0;

      // Update view to show loading bar
      notifyListeners();
      
      // pass the images back to the respository for processing and saving
      _imageRepository.sendImagesToGemini(imgList).listen((count) {
        // Update the total no. of images processed
        _processedImgCount = count;

        if (_processedImgCount >= _totalImgCount) {
          _isProcessing = false;
        }

        // Update loading bar in view
        notifyListeners();
      });

    }
}
