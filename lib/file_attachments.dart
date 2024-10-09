import 'package:file_selector/file_selector.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mime/mime.dart';
import 'package:web_app/Analytics.dart';
import 'package:web_app/util.dart';

// The file attachment workflow has two main parts:
// 1. the AttachmentsManager which "collects" files to be uploaded together,
//    probably as part of a form submission, and
// 2. the PickAttachmentDialog which adds a single file to the manager.

String formatFileSize(int sizeBytes, {int round = 2}) {
  const List<String> affixes = ['B', 'kB', 'MB', 'GB', 'TB', 'PB'];
  final divider = 1024;

  var currDivider = 0;
  var currAffix = 0;
  var nextDivider = divider;

  while (sizeBytes >= nextDivider && currAffix < affixes.length - 1) {
    currDivider = nextDivider;
    nextDivider *= divider;
    currAffix++;
  }

  var size = sizeBytes.toDouble();
  if (currDivider > 0) size /= currDivider;
  var result = size.toStringAsFixed(round);

  // Trim off trailing zeros.
  if (result.endsWith("0" * round))
    result = result.substring(0, result.length - round - 1);

  return "${result} ${affixes[currAffix]}";
}

/// A file which has been picked by the user but hasn't yet been uploaded.
class FileUpload {
  final XFile file;
  final String displayName;
  final String fileName;
  final int fileSize;
  final String mimeType;

  FileUpload({
    required this.file,
    required this.displayName,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
  });
}

/// A file which has been uploaded to Cloud Storage as an attachment.
class Attachment {
  final String name;
  final int fileSize;
  final String mimeType;
  final String url;

  Attachment({
    required this.name,
    required this.fileSize,
    required this.mimeType,
    required this.url,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      name: json['name'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "fileSize": fileSize,
      "mimeType": mimeType,
      "url": url,
    };
  }
}

/// Uploads the set of files listed in `uploads` to the Cloud Storage attachments bucket.
/// `path` is where in the bucket to store the files; the file's `fileName`
/// is appended to this to get the full path.
/// To monitor progress you can pass an optional `onProgress` function which
/// will be called periodically with the ratio of uploaded bytes to total bytes
/// as each file is uploaded. It starts at 0 for each file, rather than being
/// a total upload progress for all attachments.
Future<List<Attachment>> uploadAttachments(
  String path,
  List<FileUpload> uploads, {
  Function(double)? onProgress,
}) async {
  final bucket = dotenv.get('ATTACHMENTS_BUCKET');
  final storageRef = FirebaseStorage.instanceFor(bucket: bucket).ref();

  final List<Attachment> results = [];
  for (var f in uploads) {
    final fileRef = storageRef.child(path).child(f.fileName);

    final uploadTask = fileRef.putData(
      await f.file.readAsBytes(),
      SettableMetadata(
        contentType: f.mimeType,
      ),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((event) {
        switch (event.state) {
          case TaskState.running:
            onProgress(event.bytesTransferred / event.totalBytes);
            break;
          default:
            break;
        }
      });
    }

    await uploadTask;

    final result = Attachment(
      name: f.displayName,
      fileSize: f.fileSize,
      mimeType: f.mimeType,
      url: await fileRef.getDownloadURL(),
    );
    results.add(result);
  }
  return results;
}

/// The dialog form for selecting a file to attach.
class PickAttachmentDialog extends StatefulWidget {
  final Function(FileUpload) onPicked;

  PickAttachmentDialog({super.key, required this.onPicked});

  @override
  State<PickAttachmentDialog> createState() => _PickAttachmentDialogState();
}

class _PickAttachmentDialogState extends State<PickAttachmentDialog> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'attach-file');

  // error message for the file button; null if no error
  String? _errorMessage = null;

  XFile? _pickedFile;
  TextEditingController _displayName = TextEditingController();
  TextEditingController _fileName = TextEditingController();
  int? _fileSize;
  String? _mimeType;

  Future<void> _openFilePicker() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'Files',
          extensions: ['*'],
        ),
      ],
    );

    if (file != null) {
      final size = await file.length();
      final headerBytes = (await file
          .openRead(0, defaultMagicNumbersMaxLength)
          .expand((xs) => xs)
          .toList());
      final mimeType = lookupMimeType(file.name, headerBytes: headerBytes);

      // debugPrint("path: ${file.path}");
      // debugPrint("name: ${file.name}");
      // debugPrint("mime: ${mimeType}");
      // debugPrint("size: ${size}");

      setState(() {
        _errorMessage = null;
        _pickedFile = file;
        _displayName.text = file.name;
        _fileName.text = file.name;
        _fileSize = size;
        _mimeType = mimeType;
      });
    }
  }

  /// Handle form submission
  void _submit() {
    // Validation: make sure we picked a file.
    _errorMessage = null;
    if (_pickedFile == null) {
      setState(() {
        _errorMessage = "Please select a file first.";
      });
      return;
    }

    // Validation: check form validation rules.
    final formState = _formKey.currentState!;
    if (!formState.validate()) {
      return;
    }

    // Save form state.
    formState.save();

    // Notify that we picked a file then close the dialog.
    widget.onPicked(FileUpload(
      file: _pickedFile!,
      displayName: _displayName.text,
      fileName: _fileName.text,
      fileSize: _fileSize!,
      mimeType: _mimeType!,
    ));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    FormFieldValidator<String> required = (value) {
      if (_pickedFile == null) {
        return null;
      }
      if (value == null || value.isEmpty) {
        return 'This value is required.';
      }
      return null;
    };

    return AlertDialog(
      title: Text('Add a file attachment'),
      content: Form(
        key: _formKey,
        child: Container(
          constraints: BoxConstraints(minWidth: 400),
          child: SingleChildScrollView(
            child: ListBody(children: [
              // Button to open OS file selection dialog.
              Padding(
                padding: fieldPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _openFilePicker,
                      child: Text('Select File'),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xffd32f2f),
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Display name
              Padding(
                padding: fieldPadding,
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "Display Name",
                    helperText:
                        "A human-friendly name for the file, shown on the site.",
                    border: OutlineInputBorder(),
                  ),
                  controller: _displayName,
                  onSaved: (value) {
                    setState(() {
                      _displayName.text = value ?? "";
                    });
                  },
                  validator: required,
                  enabled: _pickedFile != null,
                ),
              ),

              // File name
              Padding(
                padding: fieldPadding,
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: "File Name",
                    helperText:
                        "The name used for the file when someone downloads it.",
                    border: OutlineInputBorder(),
                  ),
                  controller: _fileName,
                  onSaved: (value) {
                    setState(() {
                      _fileName.text = value ?? "";
                    });
                  },
                  validator: required,
                  enabled: _pickedFile != null,
                ),
              ),

              // File size
              Padding(
                padding: fieldPadding,
                child: Text(
                    "File Size: ${_fileSize != null ? formatFileSize(_fileSize!) : "---"}"),
              ),

              // MIME type
              Padding(
                padding: fieldPadding,
                child: Text("Mime Type: ${_mimeType ?? "---"}"),
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text("Attach"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _displayName.dispose();
    _fileName.dispose();
    super.dispose();
  }
}

const EdgeInsets fieldPadding = EdgeInsets.symmetric(vertical: 8.0);

/// A form widget for including file attachments.
/// Designed for a display width of 600.
class AttachmentsManager extends StatefulWidget {
  final Function(List<FileUpload>) onChanged;

  AttachmentsManager({super.key, required this.onChanged});

  @override
  State<StatefulWidget> createState() => _AttachmentsManagerState();
}

class _AttachmentsManagerState extends State<AttachmentsManager> {
  final _attachments = <FileUpload>[];

  DataColumn _column(String label) {
    return DataColumn(
      label: Expanded(
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Table listing the chosen attachments with a button to remove a file.
        DataTable(
          columns: [
            "Name",
            "Size",
            "Type",
            "", // remove button
          ].map(_column).toList(),
          columnSpacing: 12.0,
          rows: _attachments.map((file) {
            return DataRow(cells: <DataCell>[
              DataCell(
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 192),
                  child: Tooltip(
                    message: file.fileName,
                    child: Text(
                      file.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 80),
                  child: Text(
                    formatFileSize(file.fileSize),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 128),
                  child: Tooltip(
                    message: file.mimeType,
                    child: Text(
                      file.mimeType,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  splashRadius: 18.0,
                  onPressed: () {
                    setState(() {
                      _attachments.remove(file);
                      widget.onChanged(_attachments);
                    });
                  },
                  tooltip: 'Remove Attachment',
                ),
              ),
            ]);
          }).toList(),
        ),

        // Show some text if there aren't any attachments chosen.
        if (_attachments.isEmpty)
          Padding(
            padding: fieldPadding,
            child: Text(
              "(no attachments)",
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Add file button.
        Padding(
          padding: fieldPadding,
          child: ElevatedButton(
            child: Text('Add a File Attachment'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => PickAttachmentDialog(
                  onPicked: (file) {
                    setState(() {
                      _attachments.add(file);
                      widget.onChanged(_attachments);
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

List<Attachment> getAttachmentsFromResource(dynamic data) {
  try {
    final xs = data['attachments'];
    if (xs is List) {
      return xs
          .map((x) => Attachment.fromJson(x as Map<String, dynamic>))
          .toList();
    } else {
      return [];
    }
  } on StateError {
    return [];
  }
}

class AttachmentsList extends StatelessWidget {
  AttachmentsList({super.key, required this.analytics, 
                                                    required this.attachments,
                                                    required this.resourceId});

  final HomeAnalytics analytics; 
  final List<Attachment> attachments;
  final String type = "attachments";
  final String resourceId;


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attachments.map((a) {
        return Row(children: [
          Link(
            analytics: analytics,
            type: type,
            text: a.name, 
            uri: Uri.parse(a.url),
            resourceId: resourceId,),
          Text(" (${a.mimeType}; ${formatFileSize(a.fileSize)})")
        ]);
      }).toList(),
    );
  }
}
