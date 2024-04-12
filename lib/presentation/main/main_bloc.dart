import 'package:image_picker/image_picker.dart';
import 'package:memogenerator/data/repositories/meme_repository.dart';

import '../../data/model/meme.dart';

class MainBloc {
  Stream<List<Meme>> observeMemes() =>
      MemesRepository.getInstance().observeMemes();

  Future<String?> selectMeme() async {
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery);
    return xfile?.path;
  }

  void dispose() {}
}
