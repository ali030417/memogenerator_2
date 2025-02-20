import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:memogenerator/data/model/meme.dart';
import 'package:memogenerator/data/model/position.dart';
import 'package:memogenerator/data/model/text_with_position.dart';
import 'package:memogenerator/data/repositories/meme_repository.dart';
import 'package:memogenerator/domain/interactors/save_meme_interactor.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

class CreateMemeBloc {
  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);
  final memeTextOffsetsSubject =
      BehaviorSubject<List<MemeTextOffset>>.seeded(<MemeTextOffset>[]);
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);
  final newMemeTextOffsetsSubject =
      BehaviorSubject<MemeTextOffset?>.seeded(null);
  final memePathSubject = BehaviorSubject<String?>.seeded(null);

  StreamSubscription<MemeTextOffset?>? newMemeTextOffsetsSubscription;
  StreamSubscription<bool>? saveMemeSubscription;
  StreamSubscription<Meme?>? exsitentMemeSubscription;

  final String id;

  CreateMemeBloc({
    final String? id,
    final String? selectedMemePath,
  }) : this.id = id ?? Uuid().v4() {
    print('got id $id');
    memePathSubject.add(selectedMemePath);
    _subscribeToNewMemeTextOffset();
    _subscribeToExistenMeme();
  }

  void _subscribeToExistenMeme() {
    exsitentMemeSubscription =
        MemesRepository.getInstance().getMeme(this.id).asStream().listen(
      (meme) {
        if (meme == null) {
          return;
        }
        print('$meme');
        final memeTexts = meme.texts.map((textWithPosition) {
          return MemeText(id: textWithPosition.id, text: textWithPosition.text);
        }).toList();
        final memeTextOffsets = meme.texts.map((textWithPosition) {
          return MemeTextOffset(
            id: textWithPosition.id,
            offset: Offset(
              textWithPosition.position.left,
              textWithPosition.position.top,
            ),
          );
        }).toList();
        memeTextsSubject.add(memeTexts);
        memeTextOffsetsSubject.add(memeTextOffsets);
        memePathSubject.add(meme.memePath);
      },
      onError: (error, stackTrace) =>
          print('Error newMemeTextOffsetsSubscription: $error, $stackTrace'),
    );
  }

  void saveMeme() {
    final memeTexts = memeTextsSubject.value;
    final memeTextOffsets = memeTextOffsetsSubject.value;
    final textsWithPosition = memeTexts.map((memeText) {
      final memeTextPosition =
          memeTextOffsets.firstWhereOrNull((memeTextOffset) {
        return memeTextOffset.id == memeText.id;
      });
      final position = Position(
        top: memeTextPosition?.offset.dy ?? 0,
        left: memeTextPosition?.offset.dx ?? 0,
      );
      return TextWithPosition(
          id: memeText.id, text: memeText.text, position: position);
    }).toList();
    saveMemeSubscription = SaveMemeInteractor.getInstance()
        .saveMeme(
          id: id,
          textWithPositions: textsWithPosition,
          imagePath: memePathSubject.value,
        )
        .asStream()
        .listen(
      (saved) {
        print('mem saved: $saved');
      },
      onError: (error, stackTrace) =>
          print('Error newMemeTextOffsetsSubscription: $error, $stackTrace'),
    );
  }

  void _subscribeToNewMemeTextOffset() {
    newMemeTextOffsetsSubscription = newMemeTextOffsetsSubject
        .debounceTime(Duration(milliseconds: 300))
        .listen(
      (newMemeTextOffset) {
        if (newMemeTextOffset != null) {
          _changeMemeTextOffsetInternal(newMemeTextOffset);
        }
      },
      onError: (error, stackTrace) =>
          print('Error newMemeTextOffsetsSubscription: $error, $stackTrace'),
    );
  }

  void changeMemeTextOffset(final String id, final Offset offset) {
    newMemeTextOffsetsSubject.add(MemeTextOffset(id: id, offset: offset));
  }

  void _changeMemeTextOffsetInternal(final MemeTextOffset newMemeTextOffset) {
    final copiedMemeTextOffsets = [...memeTextOffsetsSubject.value];
    final currentMemeTextOffset = copiedMemeTextOffsets.firstWhereOrNull(
        (memeTextOffset) => memeTextOffset.id == newMemeTextOffset.id);
    if (currentMemeTextOffset != null) {
      copiedMemeTextOffsets.remove(currentMemeTextOffset);
    }
    copiedMemeTextOffsets.add(newMemeTextOffset);
    memeTextOffsetsSubject.add(copiedMemeTextOffsets);
    print('got new offset $newMemeTextOffset');
  }

  void addNewText() {
    final newMemeText = MemeText.create();
    memeTextsSubject.add([...memeTextsSubject.value, newMemeText]);
    selectedMemeTextSubject.add(newMemeText);
  }

  void changeMemeText(final String id, final String text) {
    final copiedList = [...memeTextsSubject.value];
    final index = copiedList.indexWhere((memeText) => memeText.id == id);
    if (index == -1) {
      return;
    }
    copiedList.removeAt(index);
    copiedList.insert(index, MemeText(id: id, text: text));
    memeTextsSubject.add(copiedList);
  }

  void selectMemeText(final String id) {
    final foundMemeText = memeTextsSubject.value
        .firstWhereOrNull((memeText) => memeText.id == id);
    selectedMemeTextSubject.add(foundMemeText);
  }

  void deselectMemeText() {
    selectedMemeTextSubject.add(null);
  }

  Stream<String?> observeMemePath() => memePathSubject.distinct();

  Stream<List<MemeText>> observeMemeTexts() => memeTextsSubject
      .distinct((prev, next) => ListEquality().equals(prev, next));

  Stream<List<MemeTextWithOffset>> observeMemeTextWithOffsets() {
    return Rx.combineLatest2<List<MemeText>, List<MemeTextOffset>,
            List<MemeTextWithOffset>>(
        observeMemeTexts(), memeTextOffsetsSubject.distinct(),
        (memeTexts, memeTextOffsets) {
      return memeTexts.map((memeText) {
        final memeTextOffset = memeTextOffsets.firstWhereOrNull((element) {
          return element.id == memeText.id;
        });
        return MemeTextWithOffset(
          id: memeText.id,
          text: memeText.text,
          offset: memeTextOffset?.offset,
        );
      }).toList();
    }).distinct((prev, next) => ListEquality().equals(prev, next));
  }

  Stream<MemeText?> observeSelectedMemeText() =>
      selectedMemeTextSubject.distinct();

  Stream<List<MemeTextWithSelection>> observeMemeTextWithSelection() {
    return Rx.combineLatest2<List<MemeText>, MemeText?,
        List<MemeTextWithSelection>>(
      observeMemeTexts(),
      observeSelectedMemeText(),
      (memeTexts, selectedMemeText) {
        return memeTexts.map((memeText) {
          return MemeTextWithSelection(
            memeText: memeText,
            selected: memeText.id == selectedMemeText?.id,
          );
        }).toList();
      },
    );
  }

  void dispose() {
    memeTextsSubject.close();
    selectedMemeTextSubject.close();
    memeTextOffsetsSubject.close();
    newMemeTextOffsetsSubject.close();
    memePathSubject.close();

    newMemeTextOffsetsSubscription?.cancel();
    saveMemeSubscription?.cancel();
    exsitentMemeSubscription?.cancel();
  }
}
