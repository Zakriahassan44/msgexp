import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:msgexp/src/flutter_msg_parser.dart';
import 'package:msgexp/src/src/parser.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Parser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FileUploadPage(),
    );
  }
}

class FileUploadPage extends StatefulWidget {
  @override
  _FileUploadPageState createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  File? _file;
  String? _status;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _status = null; // Clear status
      });
    } else {
      setState(() {
        _status = 'No file selected';
      });
    }
  }

  Future<void> parseFile() async {
    if (_file == null) {
      setState(() {
        _status = 'Please select a file first';
      });
      return;
    }

    try {
      final fileBytes = await _file!.readAsBytes();
      print('File Bytes Length: ${fileBytes.length}'); // Log file bytes length

      MsgParseResult result;
      try {
        result = await parseMsg(fileBytes); // Ensure correct function is used
      } catch (e) {
        print('Error parsing .msg file with flutter_msg_parser: $e');
        setState(() {
          _status = 'Error parsing file: $e';
        });
        return;
      }

      // Check if any fields are null
      final emailData = {
        'subject': result.subject ?? 'No Subject', // Check if subject is null
        'from': result.from ?? 'Unknown Sender', // Check if from is null or already a String
        'recipients': result.recipients.toString() != null
            ? result.recipients!.map((recipient) => recipient.name.toString() ?? 'Unknown Recipient').toList() // Check if recipients are null
            : [],
        'text': result.text ?? 'No Text Content', // Check if text is null
        'html': result.html ?? 'No HTML Content', // Check if HTML is null
        'attachments': result.attachments != null
            ? result.attachments!.map((attachment) => attachment.name ?? 'No Filename').toList() // Check if attachments are null
            : [],
      };


      print('Parsed Subject: ${emailData['subject']}');
      print('Parsed From: ${emailData['from']}');
      print('Parsed Recipients: ${emailData['recipients']}');
      print('Parsed Text: ${emailData['text']}');
      print('Parsed HTML: ${emailData['html']}');
      print('Parsed Attachments: ${emailData['attachments']}');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParsedFilePage(emailData: emailData),
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Error processing file: $e';
      });
      print('Error processing file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload and Parse File'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: Text('Pick .msg File'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: parseFile,
              child: Text('Parse File'),
            ),
            SizedBox(height: 20),
            if (_status != null) Text(_status!),
          ],
        ),
      ),
    );
  }
}

class ParsedFilePage extends StatelessWidget {
  final Map<String, dynamic> emailData;

  ParsedFilePage({required this.emailData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parsed File Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${emailData['subject']}'),
            Text('From: ${emailData['from']}'),
            Text('Recipients: ${emailData['recipients'].join(', ')}'),
            Text('Text Content: ${emailData['text']}'),
            Text('HTML Content: ${emailData['html']}'),
            SizedBox(height: 20),
            if (emailData['attachments'] != null && emailData['attachments'].isNotEmpty)
              ...emailData['attachments'].map((attachment) => Text('Attachment: $attachment')).toList(),
          ],
        ),
      ),
    );
  }
}
