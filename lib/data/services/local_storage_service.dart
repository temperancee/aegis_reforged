
import 'package:aegis_reforged/utils/result.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class LocalStorageService {

  Future<Result<List<AssetEntity>>> getSelectedImages() async {
    // Bring up photo/album select screen
    final PermissionState ps = await PhotoManager.requestPermissionExtend(); // the method can use optional param `permission`.
    if (ps.isAuth) {
      // Granted
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: const AssetPickerConfig(maxAssets: 500)
      );
      if (result != null) {
        // At this point, you have the data
      }
    } else if (ps.hasAccess) {
      // Access will continue, but the amount visible depends on the user's selection.
    } else {
      // Limited(iOS) or Rejected - open settings for further steps.
      // Throw a pop-up here saying permissions need to be enabled (I think these are called snackbars)
      PhotoManager.openSetting(); 
    }
  }
}

