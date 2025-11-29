
import 'package:aegis_reforged/ui/photo_upload/view_model/photo_upload_view_model.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoUploadScreen extends StatelessWidget {
  const PhotoUploadScreen({super.key, required this.viewModel});

  final PhotoUploadViewModel viewModel;
  @override
    Widget build(BuildContext context) {
      IconData icon = Icons.upload;

      return Center(
        // We essentially want to reload the whole screen on updates,
        // since originally the screen shows a button, then it shows a loading bar
        // with nothing remaining unchanged on the screen
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            if (viewModel.isProcessing) {

              // Display loading bar as images are being processed
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LinearProgressIndicator(
                    value: viewModel.progressPercentage,
                    minHeight: 10,
                  ),
                  Text("Images processed ${viewModel.processedImgCount} / ${viewModel.totalImgCount}")
                ],
              );


            } else {
              
              // Display button to upload images
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    // This funtion needs to be replaced with a viewmodel callback
                    onPressed: () async {
                      // Bring up photo/album select screen
                      final PermissionState ps = await PhotoManager.requestPermissionExtend(); // the method can use optional param `permission`.

                     /* 
                      * If the context is not currently mounted, i.e., this widget is no longer in the
                      * tree (likely because the user navigated away from the page while the function
                      * was awaiting the return above), return from this function. This means the
                      * user has to click this button again, but it prevents us passing an unmounted
                      * context to pickAssets() below, which may cause a crash
                      */
                      if (!context.mounted) return;

                      if (ps.isAuth) {
                        // Granted
                        final List<AssetEntity>? result = await AssetPicker.pickAssets(context);
                        // Null is returned if the user cancels the operation, in which case we do nothing
                        if (result != null) {
                          // At this point, you have the data, so pass it back to the viewmodel
                          viewModel.processImages(result);
                        }
                      } else if (ps.hasAccess) {
                        // Access will continue, but the amount visible depends on the user's selection.
                      } else {
                        // Limited(iOS) or Rejected - open settings for further steps.
                        PhotoManager.openSetting(); 
                      }
                    },
                    icon: Icon(icon),
                    label: Text("Upload photos")
                  )
                ],
              );

            }
          }
        )
      );
    }
}
