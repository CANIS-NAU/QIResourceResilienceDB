import 'package:flutter/material.dart';

// Accessibility Check: https://webaim.org/resources/contrastchecker/?fcolor=FFFFFF&bcolor=AE1409
class DeleteButton extends StatelessWidget {

  final String label;
  final VoidCallback onPressed;

  const DeleteButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color(0xFFFFFFFF),
        backgroundColor: const Color(0xFFAE1409),
      ), 
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold),)
      );
  }
} 
// Accessibility Check: https://webaim.org/resources/contrastchecker/?fcolor=595959&bcolor=FFFFFF
class CancelButton extends StatelessWidget {
  
  final String label;
  final VoidCallback onPressed;

  const CancelButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF595959),
      ),
      onPressed: onPressed,
      child: Text(label)
    );
  }

}
class CustomRadioList<T> extends StatelessWidget {
  final Map<T, String> options;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final TextStyle? labelStyle;
  final FocusNode? focusNode;

  const CustomRadioList(
      {super.key,
      required this.options,
      required this.selectedValue,
      required this.onChanged,
      this.labelStyle,
      this.focusNode});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.entries.map((entry) {
        final value = entry.key;
        final label = entry.value;

        return RadioListTile<T>(
            title: Text(label, style: labelStyle),
            value: value,
            groupValue: selectedValue,
            onChanged: onChanged,
            focusNode: focusNode ?? FocusNode(skipTraversal: true),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true);
      }).toList(),
    );
  }
}

class CustomTextFieldContainer extends StatelessWidget {
  final String label;
  final bool isVisible;
  final TextEditingController? controller;

  const CustomTextFieldContainer({
    Key? key,
    required this.label,
    required this.isVisible,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible){
      return SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: isVisible ? 8.0 : 0.0),
      child: TextField(
        controller: controller,
        obscureText: false,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: label,
        ),
      ),
    );
  }
}

// Custom checkbox list widget to display a list of checkboxes with labels
// This widget allows multiple selections from a list of options.
class CustomCheckboxList extends StatelessWidget {
  final Map<String, String> options;
  final Set<String> selectedOptions;
  final ValueChanged<String> onChanged; 
  final TextStyle? labelStyle;
  final FocusNode? focusNode;

  const CustomCheckboxList(
    {
      super.key,
      required this.options,
      required this.selectedOptions,
      required this.onChanged,
      this.labelStyle,
      this.focusNode
    }
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.entries.map( (entry) {
        final key = entry.key;
        final label = entry.value;

        return CheckboxListTile(
          title: Text(
            label, 
            style: labelStyle,
          ),
          value: selectedOptions.contains(key),
          onChanged: (bool? value) {
            if (value != null) onChanged(key);
          },
          controlAffinity: ListTileControlAffinity.leading,
          focusNode: focusNode ?? FocusNode(skipTraversal: true),
        );
      }).toList()
    );
  }
}