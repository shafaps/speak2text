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
  List<Note> notes = [];

  // Deklarasikan contentController di sini
  TextEditingController contentController = TextEditingController();

  DateTime _currentDateTime = DateTime.now();

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        // Handle status changes (optional)
        print("Speech recognition status: $status");
      },
    );

    if (available) {
      setState(() {
        _speech.listen(
          onResult: (result) {
            setState(() {
              _recordedText = result.recognizedWords;
              // Perbarui teks pada controller contentController
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
    loadNotesFromLocal(); // Panggil metode ini saat widget diinisialisasi
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
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
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
                  setState(() {
                    notes.removeAt(index);
                  });
                },
              ),
              onTap: () {
                _editNote(index);
              },
            ),
          );
        },
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

  void _addNote() {
    showDialog(
      context: context,
      builder: (context) {
        final newNote = Note(
          title: 'Judul Catatan', // Sesuaikan dengan judul yang sesuai
          content: _recordedText,
          dateTime: DateTime.now(),
        );
        // Fungsi ini akan dipanggil ketika tombol "Simpan" ditekan pada dialog "Tambah Catatan"
        void saveNote() async {
          if (newNote.title.isNotEmpty) {
            newNote.content = _recordedText;
            newNote.dateTime = DateTime.now();
            setState(() {
              notes.add(newNote);
              _recordedText = '';
              notes.sort((a, b) => a.dateTime.compareTo(b.dateTime));
            });

            // Simpan catatan baru ke Shared Preferences
            await saveNotesToLocal();
            Navigator.of(context).pop();
          } else {
            // Tampilkan pesan kesalahan jika judul catatan kosong
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
          title: Text('Tambah Catatan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  onChanged: (value) {
                    newNote.title = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Judul Catatan',
                  ),
                ),
                SizedBox(
                  height: 20,
                ), // Hanya satu elemen SizedBox diperlukan di sini
                TextFormField(
                  controller: contentController,
                  onChanged: (value) {
                    // Do nothing here, as we'll update it with speech recognition result
                  },
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Isi Catatan',
                  ),
                ),
                SizedBox(height: 20), // Tambahkan SizedBox untuk pemisahan
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
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed:
                  saveNote, // Panggil fungsi saveNote ketika tombol "Simpan" ditekan
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

    // Simpan list catatan sebagai string JSON ke Shared Preferences
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
            editedNote.dateTime =
                DateTime.now(); // Setel waktu saat catatan diedit
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

  // Tambahkan metode ini untuk mengkonversi objek Note menjadi Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  // Tambahkan metode ini untuk membuat objek Note dari Map
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      title: map['title'],
      content: map['content'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}
