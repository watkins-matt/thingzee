import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final itemThumbnailCache =
    StateNotifierProvider<ItemThumbnailCache, Map<String, Image>>((ref) => ItemThumbnailCache());

class ItemThumbnailCache extends StateNotifier<Map<String, Image>> {
  Map<String, String> fileNames = {};

  ItemThumbnailCache() : super({}) {
    _init();
  }

  Future<void> _init() async {
    await loadMapping();
    await refresh();
  }

  Future<void> loadMapping() async {
    final directory = await getApplicationDocumentsDirectory();
    final mappingPath = '${directory.path}/image_file_map.csv';

    if (File(mappingPath).existsSync()) {
      final csvFile = await File(mappingPath).readAsString();
      List<List<String>> csvData =
          const CsvToListConverter().convert(csvFile, shouldParseNumbers: false);

      for (final List<String> row in csvData) {
        String upc = row[0];
        String fileName = row[1];

        // Skip the header row
        if (upc == 'upc') {
          continue;
        }

        fileNames[upc] = fileName;
      }
    }
  }

  Future<void> saveMapping() async {
    final directory = await getApplicationDocumentsDirectory();
    final mappingPath = '${directory.path}/image_file_map.csv';
    final csvFile = File(mappingPath);

    var rows = fileNames.entries.map((entry) => [entry.key, entry.value]).toList();
    rows.insert(0, ['upc', 'file_name']); // Add a header row

    final csvData = const ListToCsvConverter().convert(rows);
    await csvFile.writeAsString(csvData);
  }

  Future<bool> downloadImage(String imageUrl, String upc) async {
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
        return false;
      } else {
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
        if (kDebugMode) {
          print('Unknown image type: $contentType');
        }
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

  bool cachedImageLoaded(String upc) {
    return state.containsKey(upc);
  }

  Future<bool> loadImageIfExists(String upc) async {
    if (cachedImageLoaded(upc)) {
      return true;
    } else if (hasCacheOnDisk(upc)) {
      return await loadImage(upc);
    }

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

  Future<void> refresh() async {
    for (final upc in fileNames.keys) {
      await loadImageIfExists(upc);
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
}
