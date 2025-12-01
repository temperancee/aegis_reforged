// I envision this app having a nav bar with 3 pages:
// - Photo review (tinder esque) page
// - Photo upload page
// - Photo selection page (this is where you implement the copy hack)
// There will also be a settings page, but I don't think the nav bar is the best place for it


import 'package:aegis_reforged/data/repositories/image_repository.dart';
import 'package:aegis_reforged/data/services/api_key.dart';
import 'package:aegis_reforged/data/services/gemini_service.dart';
import 'package:aegis_reforged/ui/photo_upload/view_model/photo_upload_view_model.dart';
import 'package:aegis_reforged/ui/photo_upload/widgets/photo_upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';

void main() {

  // Since this is only used in the photoupload page, perhaps it should be part 
  // of the related viewmodel (or, perhaps more likely, part of the gemini/photo
  // repository?)
  Gemini.init(apiKey: apiKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Aegis Reforged',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: HomePage(),
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = PhotoUploadScreen(viewModel: PhotoUploadViewModel(imageRepository: ImageRepository(gemini: GeminiService())),);
      case 1:
        page = PhotoReviewPage();
      case 2:
        page = PhotoSelectionPage();
      default:
        throw UnimplementedError('No widget for $selectedIndex');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.upload),
                      label: Text('Upload'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.web_stories),
                      label: Text('Review'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.filter),
                      label: Text('Gallery'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}


class PhotoSelectionPage extends StatelessWidget {
  @override
    Widget build(BuildContext context) {
      // TODO: implement build
      throw UnimplementedError();
    }
}

class PhotoReviewPage extends StatelessWidget {
  @override
    Widget build(BuildContext context) {

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("TITLE"), //TODO: Update with title variable
            Row(
              children: [
                // TODO: Add arrows and picture here
              ],
            ),
            // TODO: Add tag rail here
            Text("Description"),
          ],
        ),
      );
    }
}

class MyAppState extends ChangeNotifier {
}
