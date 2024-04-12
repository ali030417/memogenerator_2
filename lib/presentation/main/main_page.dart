import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import '../../data/model/meme.dart';
import 'main_bloc.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.darcGrey,
          title: Text('Мемогенератор',
              style: GoogleFonts.seymourOne(fontSize: 24)),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final selectedMemePath = await bloc.selectMeme();
            if (selectedMemePath == null) {
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateMemePage(
                  selectedMemePath: selectedMemePath,
                ),
              ),
            );
          },
          backgroundColor: AppColors.fuchsia,
          icon: Icon(
            Icons.add,
            color: Colors.white,
          ),
          label: Text('Создать'),
        ),
        body: SafeArea(
          child: MainPageContant(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class MainPageContant extends StatefulWidget {
  const MainPageContant({super.key});

  @override
  State<MainPageContant> createState() => _MainPageContantState();
}

class _MainPageContantState extends State<MainPageContant> {
  late FocusNode searchFieldFocusNode;

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder(
      stream: bloc.observeMemes(),
      initialData: const <Meme>[],
      builder: (context, snapshot) {
        final items = snapshot.hasData ? snapshot.data! : const <Meme>[];
        return ListView(
          children: items.map((item) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return CreateMemePage(id: item.id);
                    },
                  ),
                );
              },
              child: Container(
                height: 48,
                padding: EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(item.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  void dispose() {
    searchFieldFocusNode.dispose();
    super.dispose();
  }
}
