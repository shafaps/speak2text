import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(NoteApp(isDarkMode: true));
}

class NoteApp extends StatelessWidget {
  final bool isDarkMode;

  NoteApp({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NoteList(),
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
  }
}

class NoteList extends StatefulWidget {
  @override
  _NoteListState createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _recordedText = '';
  String _recordedTitle = '';
  List<Note> notes = [];

  TextEditingController contentController = TextEditingController();
  TextEditingController titleController =
      TextEditingController(); // Tambahkan controller judul

  DateTime _currentDateTime = DateTime.now();

  Note newNote = Note(
    title: 'judul catatan',
    content: '',
    dateTime: DateTime.now(),
  ); // Deklarasi variabel newNote

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("Speech recognition status: $status");
      },
    );

    if (available) {
      setState(() {
        _recordedText = '';
        _speech.listen(
          onResult: (result) {
            setState(() {
              _recordedText = result.recognizedWords;
              contentController.text = _recordedText;
            });
          },
        );
      });
    } else {
      print('Permission denied or no available speech recognition modules.');
    }
  }

  void _stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
  }

  void _startListeningForTitle() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("Speech recognition status: $status");
      },
    );

    if (available) {
      setState(() {
        _recordedTitle = '';
        _speech.listen(
          onResult: (result) {
            setState(() {
              _recordedTitle = result.recognizedWords;
              titleController.text =
                  _recordedTitle; // Isi judul dengan teks yang terdeteksi
            });
          },
        );
      });
    } else {
      print('Permission denied or no available speech recognition modules.');
    }
  }

  void _stopListeningForTitle() {
    if (_speech.isListening) {
      _speech.stop();
    }
  }

  Future<void> loadNotesFromLocal() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final notesData = sharedPreferences.getString('notes');

    if (notesData != null) {
      final notesList = jsonDecode(notesData) as List<dynamic>;
      final loadedNotes = <Note>[];

      for (final noteData in notesList) {
        loadedNotes.add(Note(
          title: noteData['title'] ?? '',
          content: noteData['content'] ?? '',
          dateTime: DateTime.parse(noteData['dateTime'] ?? ''),
        ));
      }

      setState(() {
        notes = loadedNotes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadNotesFromLocal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Catatan',
          style: TextStyle(
            fontFamily: 'Pacifico',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
        child: ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return _buildNoteItem(index);
          },
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: _addNote,
                child: Icon(Icons.add),
              ),
              SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteItem(int index) {
    final note = notes[index];
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Text(
          note.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.content),
            Text(
              '${DateFormat('yyyy-MM-dd HH:mm').format(note.dateTime)}',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            _deleteNote(index);
          },
        ),
        onTap: () {
          _editNote(index);
        },
      ),
    );
  }

  void _addNote() {
    showDialog(
      context: context,
      builder: (context) {
        Note newNote = Note(
          title: 'judul catatan',
          content: '',
          dateTime: DateTime.now(),
        );

        void saveNote() async {
          newNote.title =
              _recordedTitle.isNotEmpty ? _recordedTitle : 'Judul Catatan';
          newNote.content = _recordedText;
          newNote.dateTime = DateTime.now();
          setState(() {
            notes.add(newNote);
            titleController.clear();
            contentController.clear();
          });

          await saveNotesToLocal();
          Navigator.of(context).pop();
        }

        return AlertDialog(
          title: Text('Tambah Catatan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  onChanged: (value) {
                    newNote.title = _recordedTitle;
                  },
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul Catatan',
                    suffixIcon: IconButton(
                      onPressed: () {
                        if (_speech.isListening) {
                          _stopListeningForTitle();
                        } else {
                          _startListeningForTitle();
                        }
                      },
                      icon: Icon(
                        _speech.isListening ? Icons.stop : Icons.mic,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: contentController,
                  onChanged: (value) {},
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Isi Catatan',
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        if (_speech.isListening) {
                          _stopListening();
                        } else {
                          _startListening();
                        }
                      },
                      child: Icon(_speech.isListening ? Icons.stop : Icons.mic),
                      backgroundColor:
                          _speech.isListening ? Colors.red : Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _recordedText = ''; // Reset nilai recordedText
                  _recordedTitle = ''; // Reset nilai recordedTitle
                });
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saveNote,
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveNotesToLocal() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final notesList = <Map<String, dynamic>>[];

    for (final note in notes) {
      notesList.add(note.toMap());
    }

    await sharedPreferences.setString('notes', jsonEncode(notesList));
  }

  void _editNote(int index) {
    showDialog(
      context: context,
      builder: (context) {
        final editedNote = notes[index];
        final TextEditingController titleController =
            TextEditingController(text: editedNote.title);
        final TextEditingController contentController =
            TextEditingController(text: editedNote.content);

        void _startListeningForEdit() async {
          bool available = await _speech.initialize(
            onStatus: (status) {
              print("Speech recognition status: $status");
            },
          );

          if (available) {
            setState(() {
              _speech.listen(
                onResult: (result) {
                  setState(() {
                    _recordedText = result.recognizedWords;
                    contentController.text = _recordedText;
                  });
                },
              );
            });
          } else {
            print(
                'Permission denied or no available speech recognition modules.');
          }
        }

        void _stopListeningForEdit() {
          if (_speech.isListening) {
            _speech.stop();
          }
        }

        void saveEditedNote() {
          if (titleController.text.isNotEmpty) {
            editedNote.title = titleController.text;
            editedNote.content = contentController.text;
            editedNote.dateTime = DateTime.now();
            setState(() {});
            Navigator.of(context).pop();
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Error'),
                  content: Text('Judul Catatan tidak boleh kosong.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        }

        return AlertDialog(
          title: const Text('Edit Catatan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  onChanged: (value) {
                    editedNote.title = value;
                  },
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul Catatan',
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  onChanged: (value) {
                    editedNote.content = value;
                  },
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Isi Catatan',
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        if (_speech.isListening) {
                          _stopListeningForEdit();
                        } else {
                          _startListeningForEdit();
                        }
                      },
                      child: Icon(_speech.isListening ? Icons.stop : Icons.mic),
                      backgroundColor:
                          _speech.isListening ? Colors.red : Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _recordedText = ''; // Reset nilai recordedText
                  _recordedTitle = ''; // Reset nilai recordedTitle
                });
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saveEditedNote,
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteNote(int index) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    notes.removeAt(index);

    final notesList = <Map<String, dynamic>>[];
    for (final note in notes) {
      notesList.add(note.toMap());
    }
    await sharedPreferences.setString('notes', jsonEncode(notesList));

    setState(() {});
  }
}

class Note {
  String title;
  String content;
  DateTime dateTime;

  Note({
    required this.title,
    required this.content,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      title: map['title'],
      content: map['content'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}
