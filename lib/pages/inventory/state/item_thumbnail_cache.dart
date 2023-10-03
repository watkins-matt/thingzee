import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:path_provider/path_provider.dart';

final itemThumbnailCache =
    StateNotifierProvider<ItemThumbnailCache, Map<String, Image>>((ref) => ItemThumbnailCache._());

class ItemThumbnailCache extends StateNotifier<Map<String, Image>> {
  Map<String, String> fileNames = {}; // Maps UPC -> file name

  ItemThumbnailCache._() : super({});

  bool cachedImageLoaded(String upc) {
    return state.containsKey(upc);
  }

  Future<bool> downloadImage(String imageUrl, String upc) async {
    assert(imageUrl.isNotEmpty && upc.isNotEmpty);

    // Don't download multiple times
    if (cachedImageLoaded(upc)) {
      return true;
    }

    late final Response<List<int>> response;

    try {
      response =
          await Dio().get<List<int>>(imageUrl, options: Options(responseType: ResponseType.bytes));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        Log.w('Image not found for $upc:$imageUrl.');
        return false;
      } else {
        Log.e('Error while downloading image for $upc:$imageUrl.', e, e.stackTrace);
        rethrow;
      }
    }

    // Extract MIME type from headers
    final contentType = response.headers.map['content-type']?.first ?? '';

    // Find the extension
    String fileExtension;
    switch (contentType) {
      case 'image/webp':
        fileExtension = '.webp';
        break;
      case 'image/jpeg':
        fileExtension = '.jpg';
        break;
      case 'image/png':
        fileExtension = '.png';
        break;
      default:
        Log.w('Unknown image type [$contentType] while processing $upc:$imageUrl.');
        fileExtension = '.img';
    }

    // Make sure the image directory exists
    final directory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory('${directory.path}/images');
    if (!imageDirectory.existsSync()) {
      await imageDirectory.create();
    }

    // Write the image to disk
    final imagePath = '${directory.path}/images/$upc$fileExtension';
    await File(imagePath).writeAsBytes(response.data!);

    // Update the mapping
    fileNames[upc] = '$upc$fileExtension';

    Image image = Image.file(File(imagePath), fit: BoxFit.fill);

    state = {...state, upc: image};
    return true;
  }

  bool hasCacheOnDisk(String upc) {
    return fileNames.containsKey(upc);
  }

  Future<void> loadAllImages() async {
    for (final upc in fileNames.keys) {
      await loadImageIfExists(upc);
    }
  }

  Future<void> loadFileMapping() async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory('${directory.path}/images');

    if (imageDirectory.existsSync()) {
      final files = imageDirectory.listSync();

      // Iterate through each file and add them to the map
      for (final file in files) {
        final fileName = file.uri.pathSegments.last;
        final upc = fileName.split('.').first;
        fileNames[upc] = fileName;
      }
    }
  }

  Future<bool> loadImage(String upc) async {
    final directory = await getApplicationDocumentsDirectory();
    String? fileName = fileNames[upc];

    // If fileName exists in the map, use it.
    if (fileName != null) {
      final imagePath = '${directory.path}/images/$fileName';

      // Check if the file exists
      if (File(imagePath).existsSync()) {
        // Create Image widget
        Image image = Image.file(File(imagePath), fit: BoxFit.fill);

        state = {...state, upc: image};
        return true;
      }
    }

    // Otherwise, try different extensions.
    final extensions = ['.jpg', '.png', '.jpeg', '.img'];

    for (final extension in extensions) {
      final imagePath = '${directory.path}/images/$upc$extension';
      if (File(imagePath).existsSync()) {
        Image image = Image.file(
          File(imagePath),
          fit: BoxFit.fill,
        );

        state = {...state, upc: image};
        return true;
      }
    }

    // We were not able to load the image
    return false;
  }

  Future<bool> loadImageFromUrl(String imageUrl, String upc) async {
    if (cachedImageLoaded(upc)) {
      return true;
    } else if (hasCacheOnDisk(upc)) {
      return await loadImage(upc);
    } else {
      return await downloadImage(imageUrl, upc);
    }
  }

  Future<bool> loadImageIfExists(String upc) async {
    if (cachedImageLoaded(upc)) {
      return true;
    } else if (hasCacheOnDisk(upc)) {
      return await loadImage(upc);
    }

    return false;
  }

  Future<void> preloadImages(List<String> upcListToPreload) async {
    for (final upc in upcListToPreload) {
      await loadImageIfExists(upc);
    }
  }

  Future<void> _init() async {
    await loadFileMapping();
  }

  static Future<ItemThumbnailCache> create() async {
    final cache = ItemThumbnailCache._();
    await cache._init();
    await cache.loadAllImages();
    return cache;
  }

  static Future<ItemThumbnailCache> withPreload(List<String> upcListToPreload) async {
    final cache = ItemThumbnailCache._();
    await cache._init();
    await cache.preloadImages(upcListToPreload);
    return cache;
  }
}
