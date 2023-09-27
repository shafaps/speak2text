import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(NoteApp());
}

class NoteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NoteList(),
      theme: ThemeData(
        primaryColor: Colors.blue,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color.fromARGB(255, 0, 21, 255),
        ),
      ),
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
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(
                notes[index].title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(notes[index].content),
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
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: _addNote,
                child: Icon(Icons.keyboard),
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
        final newNote = Note();

        // Fungsi ini akan dipanggil ketika tombol "Simpan" ditekan pada dialog "Tambah Catatan"
        void saveNote() {
          newNote.title = contentController.text;
          newNote.content = _recordedText; // Menggunakan teks yang diakui dari pengenalan suara
          setState(() {
            notes.add(newNote);
            _recordedText = ''; // Hapus teks yang sudah disimpan
          });
          Navigator.of(context).pop();
        }

  return AlertDialog(
    title: Text('Tambah Catatan'),
    content: Column(
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
        SizedBox(height: 20), // Tambahkan SizedBox untuk pemisahan
        Divider(height: 1, color: Colors.black), // Atau gunakan Divider untuk pemisahan
        SizedBox(height: 20), // Tambahkan SizedBox lagi untuk jarak
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
              backgroundColor: _speech.isListening ? Colors.red : Colors.blue,
            ),
          ],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text('Batal'),
      ),
            ElevatedButton(
              onPressed: saveNote, // Panggil fungsi saveNote ketika tombol "Simpan" ditekan
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }



  void _editNote(int index) {
    showDialog(
      context: context,
      builder: (context) {
        final editedNote = notes[index];
        return AlertDialog(
          title: const Text('Edit Catatan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                onChanged: (value) {
                  editedNote.title = value;
                },
                controller: TextEditingController(text: editedNote.title),
                decoration: InputDecoration(
                  labelText: 'Judul Catatan',
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                onChanged: (value) {
                  editedNote.content = value;
                },
                controller: TextEditingController(text: editedNote.content),
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Isi Catatan',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {});
                Navigator.of(context).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}

class Note {
  String title = '';
  String content = '';
}


