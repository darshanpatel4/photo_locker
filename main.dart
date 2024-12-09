import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(PhotoLockerApp());
}

class PhotoLockerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Locker',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _checkPasswordSet(context);

    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Check if password is set
  void _checkPasswordSet(BuildContext context) async {
    final storage = FlutterSecureStorage();
    final passwordSet = await storage.read(key: 'user_password');
    if (passwordSet == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SetPasswordScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => EnterPasswordScreen()),
      );
    }
  }
}

class SetPasswordScreen extends StatefulWidget {
  @override
  _SetPasswordScreenState createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Create your password (4-6 digits)",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6, // Maximum length of 6 digits
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setPassword,
              child: Text('Set Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _setPassword() async {
    final password = _passwordController.text;
    if (password.length >= 4 && password.length <= 6) {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'user_password', value: password);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => EnterPasswordScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be 4 to 6 digits long!')),
      );
    }
  }
}

class EnterPasswordScreen extends StatefulWidget {
  @override
  _EnterPasswordScreenState createState() => _EnterPasswordScreenState();
}

class _EnterPasswordScreenState extends State<EnterPasswordScreen> {
  final _passwordController = TextEditingController();
  String? _storedPassword;

  @override
  void initState() {
    super.initState();
    _getStoredPassword();
  }

  Future<void> _getStoredPassword() async {
    final storage = FlutterSecureStorage();
    _storedPassword = await storage.read(key: 'user_password');
    setState(() {}); // Update the UI when the password is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Enter your password",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6, // Maximum length of 6 digits
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyPassword,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyPassword() async {
    final enteredPassword = _passwordController.text;
    if (_storedPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading password')),
      );
    } else if (enteredPassword == _storedPassword) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AlbumListScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect password!')),
      );
    }
  }
}

// Album List Screen to manage albums
class AlbumListScreen extends StatefulWidget {
  @override
  _AlbumListScreenState createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  List<String> albums = [];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    String? albumsJson = await storage.read(key: 'albums');
    if (albumsJson != null) {
      List<String> storedAlbums = List<String>.from(jsonDecode(albumsJson));
      setState(() {
        albums = storedAlbums;
      });
    }
  }

  Future<void> _addAlbum(String albumName) async {
    setState(() {
      albums.add(albumName);
    });
    await storage.write(key: 'albums', value: jsonEncode(albums));
  }

  Future<void> _deleteAlbum(int index) async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Album"),
          content: Text("Are you sure you want to delete this album? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false if canceled
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true if confirmed
              },
              child: Text("Delete"),
              style: TextButton.styleFrom(foregroundColor: Colors.red), // Highlight the delete button
            ),
          ],
        );
      },
    );

    // If the user confirmed deletion, proceed with deleting the album
    if (confirmDelete == true) {
      setState(() {
        albums.removeAt(index);
      });
      await storage.write(key: 'albums', value: jsonEncode(albums));
    }
  }


  void _showCreateAlbumDialog() {
    TextEditingController albumController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create Album'),
          content: TextField(
            controller: albumController,
            decoration: InputDecoration(hintText: 'Enter album name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String albumName = albumController.text;
                if (albumName.isNotEmpty) {
                  _addAlbum(albumName);
                }
                Navigator.of(context).pop();
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Albums"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateAlbumDialog,
          ),
        ],
      ),
      body: albums.isEmpty
          ? Center(child: Text("No albums created yet"))
          : ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(albums[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteAlbum(index),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PhotoGalleryScreen(
                          albumName: albums[index],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// Updated PhotoGalleryScreen to use album name
class PhotoGalleryScreen extends StatefulWidget {
  final String albumName;

  PhotoGalleryScreen({required this.albumName});

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  List<String> _base64Images = [];
  final storage = FlutterSecureStorage();
  List<int> _selectedIndices = []; // Tracks selected images

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _pickImage,
          ),
        ],
      ),
      body: _base64Images.isEmpty
          ? Center(child: Text("No photos added yet"))
          : Stack(
              children: [
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Increase to 4 or more if needed
                    crossAxisSpacing: 8.0, // Adjust spacing between columns
                    mainAxisSpacing: 8.0, // Adjust spacing between rows
                    childAspectRatio: 1, // Set to 1 for square items
                  ),
                  itemCount: _base64Images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        if (_selectedIndices.isEmpty) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageView(
                                base64Images: _base64Images,
                                initialIndex: index,
                              ),
                            ),
                          );
                        } else {
                          _toggleSelection(index);
                        }
                      },
                      onLongPress: () {
                        _toggleSelection(index);
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              base64Decode(_base64Images[index]),
                              fit: BoxFit
                                  .cover, // Make sure images fill their containers
                            ),
                          ),
                          if (_selectedIndices.contains(index))
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.check_circle,
                                  color: Colors.teal, size: 24),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                if (_selectedIndices.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.delete),
                      onPressed: _deleteSelectedImages,
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _loadImages() async {
    String? storedImagesJson =
        await storage.read(key: '${widget.albumName}_images');
    if (storedImagesJson != null) {
      List<String> storedImages =
          List<String>.from(jsonDecode(storedImagesJson));
      setState(() {
        _base64Images = storedImages;
      });
    }
  }

  Future<void> _pickImage() async {
    List<XFile>? pickedImages = await _picker.pickMultiImage();

    if (pickedImages != null) {
      for (var image in pickedImages) {
        File imageFile = File(image.path);
        String base64Image = base64Encode(await imageFile.readAsBytes());
        setState(() {
          _base64Images.add(base64Image);
        });
      }
      await _saveImages();
    }
  }

  Future<void> _saveImages() async {
    String imagesJson = jsonEncode(_base64Images);
    await storage.write(key: '${widget.albumName}_images', value: imagesJson);
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _deleteSelectedImages() async {
    setState(() {
      _selectedIndices.sort((a, b) => b.compareTo(a));
      for (int index in _selectedIndices) {
        _base64Images.removeAt(index);
      }
      _selectedIndices.clear();
    });
    await _saveImages(); // Save changes to storage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected images deleted')),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final List<String> base64Images;
  final int initialIndex;

  FullScreenImageView({required this.base64Images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        itemCount: base64Images.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return Center(
            child: Image.memory(
              base64Decode(base64Images[index]),
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
