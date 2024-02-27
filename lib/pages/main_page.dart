import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:memogenerator/pages/create_meme_page.dart.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import '../blocs/main_bloc.dart';

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
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateMemePage(),
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
    return Center(
      child: Container(),
    );
  }

  @override
  void dispose() {
    searchFieldFocusNode.dispose();
    super.dispose();
  }
}
