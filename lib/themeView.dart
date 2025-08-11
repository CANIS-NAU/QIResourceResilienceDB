import 'package:flutter/material.dart';
import 'package:web_app/widgets.dart';
import 'package:web_app/theme.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool darkMode = false;
  

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: ThemeView(
        onToggleDarkMode: () => setState(() => darkMode = !darkMode),
        darkMode: darkMode,
      ),
    );
  }
}

class ThemeView extends StatefulWidget {
  final VoidCallback onToggleDarkMode;
  final bool darkMode;

  const ThemeView({
    super.key,
    required this.onToggleDarkMode,
    required this.darkMode,
  });

  @override
  State<ThemeView> createState() => _ThemeViewState();
}

class _ThemeViewState extends State<ThemeView> {
  bool testBool = false;
  double sliderValue = 0.5;
  String selectedValue = 'One';
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Theme Gallery"),
        actions: [
          IconButton(
            icon: Icon(widget.darkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.onToggleDarkMode,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("Buttons", _buildButtons()),
            _section("Selection Controls", _buildSelectionControls()),
            _section("Text Inputs", _buildTextInputs()),
            _section("Chips", _buildChips()),
            _section("Progress Indicators", _buildProgress()),
            _section("Cards", _buildCards()),
            _section("Dialogs", _buildDialogs(context)),
            _section("Sliders", _buildSliders()),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildButtons() {
    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton(onPressed: () {}, child: const Text("Confirm")),
        DeleteButton(label: "Delete", onPressed: () {}),
        FilledButton(onPressed: () {}, child: const Text("Filled")),
        OutlinedButton(onPressed: () {}, child: const Text("Outlined")),
        TextButton(onPressed: () {}, child: const Text("Text")),
        CancelButton(label: "Cancel", onPressed: () {}),
        IconButton(onPressed: () {}, icon: const Icon(Icons.favorite)),
        FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildSelectionControls() {
    return Wrap(
      spacing: 16,
      children: [
        Checkbox(
          value: testBool,
          onChanged: (val) => setState(() => testBool = val ?? false),
        ),
        Switch(
          value: testBool,
          onChanged: (val) => setState(() => testBool = val),
        ),
        DropdownButton<String>(
          value: selectedValue,
          items: const [
            DropdownMenuItem(value: 'One', child: Text('One')),
            DropdownMenuItem(value: 'Two', child: Text('Two')),
          ],
          onChanged: (val) => setState(() => selectedValue = val ?? 'One'),
        ),
      ],
    );
  }

  Widget _buildTextInputs() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: "Text Field"),
          ),
        ),
        SizedBox(
          width: 250,
          child: TextField(
            decoration: const InputDecoration(
              labelText: "Password",
              suffixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
        ),
      ],
    );
  }

  Widget _buildChips() {
    return Wrap(
      spacing: 8,
      children: [
        Chip(label: const Text("Chip")),
        InputChip(
          label: const Text("Input"),
          onPressed: () {},
        ),
        ChoiceChip(
          label: const Text("Choice"),
          selected: true,
          onSelected: (_) {},
        ),
        FilterChip(
          label: const Text("Filter"),
          selected: false,
          onSelected: (_) {},
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Wrap(
      spacing: 20,
      children: const [
        CircularProgressIndicator(),
        LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildCards() {
    return Wrap(
      spacing: 16,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                Text("Card Title", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Some example text in a card."),
              ],
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.label),
          title: const Text("List Tile"),
          subtitle: const Text("Subtitle here"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDialogs(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Dialog"),
            content: const Text("This is a sample dialog."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      },
      child: const Text("Show Dialog"),
    );
  }

  Widget _buildSliders() {
    return Slider(
      value: sliderValue,
      onChanged: (v) => setState(() => sliderValue = v),
    );
  }
}
