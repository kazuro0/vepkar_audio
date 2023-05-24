import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(
  const MaterialApp(
    home: MyApp(),
  )
);

class DetailPage extends StatelessWidget {
  late final AudioPlayer audioPlayer;
  final String word;
  final String description;
  final String part;
  final String audioPath;

  DetailPage(
      {Key? key,
        required this.word,
        required this.part,
        required this.description,
        required this.audioPath})
      : super(key: key) {
    audioPlayer = AudioPlayer();
  }

  void playAudio(audioPath) async {
    final player = AudioCache(prefix: "");
    var url = await player.load(audioPath);
    audioPlayer.play(url.toString(), isLocal: true);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.red,
        title: const Text('Karelian Multimedia Dictionary',
            style: TextStyle(
                fontFamily: 'Centro',
                fontWeight: FontWeight.w600,
                fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            word,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, fontFamily: 'Open Sans'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Text.rich(
              TextSpan(
                  text: 'часть речи: ',
                  style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Open Sans'),
                  children: <TextSpan>[
                    TextSpan(
                      text: part,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Open Sans')
                    )
                  ]),
            ),
          ),
          Text.rich(
            TextSpan(
                text: 'значения:\n',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Open Sans'),
                children: <TextSpan>[
                  TextSpan(
                    text: description,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Open Sans'),
                  )
                ]),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 30, right: 20),
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: () {
            playAudio(audioPath);
          },
          backgroundColor: Colors.red,
          child: const Icon(Icons.play_arrow_rounded, size: 40),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<List<dynamic>> _loadJSONData() async {
    String jsonString = await rootBundle.loadString('assets/dict.json');
    final jsonResponse = json.decode(jsonString);
    return jsonResponse;
  }

  AudioPlayer audioPlayer = AudioPlayer();
  bool _isSearching = false;
  var modes = ['В начале слова', 'Внутри слова', 'В конце слова'];
  String _searchMode = '';
  int currentIndex = 0;
  var value = "";
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _filteredData = [];
  AsyncSnapshot<List<dynamic>>? _snapshot;

  void updateState(String text) {
    if (_searchMode == modes[0]) {
      _filteredData = _snapshot!.data!.where((element) {
        return element['lemma'].toLowerCase().startsWith(text.toLowerCase());
      }).toList();
    } else if (_searchMode == modes[1]) {
      _filteredData = _snapshot!.data!.where((element) {
        return element['lemma'].toLowerCase().contains(text.toLowerCase());
      }).toList();
    } else if (_searchMode == modes[2]) {
      _filteredData = _snapshot!.data!.where((element) {
        return element['lemma'].toLowerCase().endsWith(text.toLowerCase());
      }).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _searchMode = modes[0];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _startSearch() {
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.red,
          title: _isSearching
              ? Container(
                  height: 43,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: Colors.white,
                  ),
                  child: TextField(
                    focusNode: _searchFocusNode,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Open Sans'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск',
                      contentPadding: const EdgeInsets.only(
                          left: 10, right: 10, bottom: 10, top: 8),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            value = "";
                            _filteredData = _snapshot!.data!;
                          });
                        },
                      ),
                    ),
                    onChanged: (text) {
                      setState(() {
                        value = text;
                        updateState(value);
                      });
                    },
                  ),
                )
              : const Text('Karelian Multimedia Dictionary',
                  style: TextStyle(
                      fontFamily: 'Centro',
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: _isSearching
                    ? const Icon(Icons.arrow_forward_outlined)
                    : const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    value = "";
                    _startSearch();
                    _isSearching = !_isSearching;
                    _filteredData = _snapshot!.data!;
                  });
                },
              ),
            )
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _loadJSONData(),
          builder:
              (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            _snapshot = snapshot;
            if (snapshot.hasData) {
              if (_filteredData.isEmpty) {
                _filteredData = snapshot.data!;
              }
              return ListView.builder(
                itemCount: _filteredData.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(
                      _filteredData[index]['lemma'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Open Sans'),
                    ),
                    subtitle: Text(
                      _filteredData[index]['meaning_text'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Open Sans'),
                      ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DetailPage(
                                  word: _filteredData[index]['lemma'],
                                  part: _filteredData[index]['part_of_speech'],
                                  description: _filteredData[index]['meaning_text'],
                                  audioPath: 'assets/audio/${_filteredData[index]['lemma_id']}.wav'
                              )));
                    },
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(
                height: 97,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.red,
                  ),
                  child: Text(
                    'Меню',
                    style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'Open Sans'),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                minLeadingWidth: 10,
                dense: true,
                visualDensity: const VisualDensity(vertical: 0),
                title: const Text(
                  'Режим поиска',
                  style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Open Sans'),
                ),
                subtitle: Text(
                  _searchMode,
                  style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Open Sans'),
                ),
                onTap: () {
                  setState(() {
                    _searchMode = modes[(currentIndex++) % modes.length];
                    updateState(value);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                minLeadingWidth: 10,
                title: const Text(
                  'О приложении',
                  style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Open Sans'),
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AboutPage()));
                },
              ),
            ],
          ),
        ),
      );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.red,
        title: const Text('О приложении',
            style: TextStyle(
                fontFamily: 'Centro',
                fontWeight: FontWeight.w600,
                fontSize: 24)),
      ),
      body: Container(
        padding: const EdgeInsets.only(left:20, right: 20, top: 30),
        child: Column(
          children: [
            Image.asset('assets/logo_about.png'),
            Container(
              padding: const EdgeInsets.only(top:10),
              child: const Text(
                'Версия от 18.05.2023',
                style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 12, fontFamily: 'Open Sans'),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top:20),
              child: const Text(
                'Приложение аудио-словаря карельского языка ливвиковского наречия.\n\nДанные взяты с сайта: dictorpus.krc.karelia.ru',
                style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 20, fontFamily: 'Open Sans'),
              ),
            ),
            Expanded(
              child: Container(), // Пустой контейнер для занятия доступного пространства
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'github.com/kazuro0/vepkar_audio',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, fontFamily: 'Open Sans', color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
