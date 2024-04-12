import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:memogenerator/data/model/meme.dart';
import 'package:memogenerator/data/model/text_with_position.dart';
import 'package:memogenerator/data/repositories/meme_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';

class SaveMemeInteractor {
  static SaveMemeInteractor? _instance;

  factory SaveMemeInteractor.getInstance() =>
      _instance ??= SaveMemeInteractor._internal();

  SaveMemeInteractor._internal();

  Future<bool> saveMeme({
    required final String id,
    required final List<TextWithPosition> textWithPositions,
    final String? imagePath,
  }) async {
    if (imagePath == null) {
      final meme = Meme(id: id, texts: textWithPositions);
      return MemesRepository.getInstance().addToMemes(meme);
    }
    final newImagePath = await createNewFile(imagePath);
    final meme = Meme(
      id: id,
      texts: textWithPositions,
      memePath: newImagePath,
    );
    return MemesRepository.getInstance().addToMemes(meme);
  }

  Future<String> createNewFile(final String imagePath) async {
    final docsPath = await getApplicationDocumentsDirectory();
    final memePath = "${docsPath.absolute.path}${Platform.pathSeparator}memes";
    final memesDirectory = Directory(memePath);
    await memesDirectory.create(recursive: true);
    final currentFiles = memesDirectory.listSync();

    final imageName = _getFileNameByPath(imagePath);
    final oldFileWithTheSameName = currentFiles.firstWhereOrNull(
      (element) {
        return _getFileNameByPath(element.path) == imageName && element is File;
      },
    );
    final newImagePath = "$memePath${Platform.pathSeparator}$imageName";
    final tempFile = File(imagePath);
    if (oldFileWithTheSameName == null) {
      await tempFile.copy(newImagePath);
      return newImagePath;
    }
    final oldFileLength = await (oldFileWithTheSameName as File).length();
    final newFileLength = await tempFile.length();
    if (oldFileLength == newFileLength) {
      return newImagePath;
    }
    return _createFileForSameNameButDifferentLength(
      imageName: imageName,
      tempFile: tempFile,
      newImagePath: newImagePath,
      memePath: memePath,
    );
  }

  Future<String> _createFileForSameNameButDifferentLength({
    required final String imageName,
    required final File tempFile,
    required final String newImagePath,
    required final String memePath,
  }) async {
    final indexOfLastDot = imageName.lastIndexOf('.');
    if (indexOfLastDot == -1) {
      await tempFile.copy(newImagePath);
      return newImagePath;
    }
    final extension = imageName.substring(indexOfLastDot);
    final imageNameWithoutExtenstion = imageName.substring(0, indexOfLastDot);
    final indexOfLastUndercore = imageNameWithoutExtenstion.lastIndexOf('_');
    if (indexOfLastUndercore == -1) {
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutExtenstion}_1$extension";
      await tempFile.copy(correctedNewImagePath);
      return correctedNewImagePath;
    }
    final suffixNumberString =
        imageNameWithoutExtenstion.substring(indexOfLastUndercore + 1);
    final suffixNumber = int.tryParse(suffixNumberString);
    if (suffixNumber == null) {
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutExtenstion}_1$extension";
      await tempFile.copy(correctedNewImagePath);
      return correctedNewImagePath;
    } else {
      final imageNameWithoutSuffix =
          imageNameWithoutExtenstion.substring(0, indexOfLastUndercore);
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutSuffix}_${suffixNumber + 1}$extension";
      await tempFile.copy(correctedNewImagePath);
      return correctedNewImagePath;
    }
  }

  String _getFileNameByPath(String imagePath) =>
      imagePath.split(Platform.pathSeparator).last;
}
