import 'package:flutter/material.dart';
// AppFlowy Editor is installed but API may vary by version
// This is a simplified implementation that can be enhanced
// For full AppFlowy integration, refer to: https://pub.dev/packages/appflowy_editor

class RichTextEditor extends StatefulWidget {
  final String? initialContent;
  final ValueChanged<String>? onChanged;
  final String? placeholder;

  const RichTextEditor({
    super.key,
    this.initialContent,
    this.onChanged,
    this.placeholder,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.initialContent ?? '',
    );
    _focusNode = FocusNode();
    
    _textController.addListener(() {
      widget.onChanged?.call(_textController.text);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Notion-style rich text editor
    // TODO: Integrate full AppFlowy Editor API when needed
    // For now, using enhanced TextField with Notion-like styling
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        minLines: 3,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              fontSize: 15,
            ),
        decoration: InputDecoration(
          hintText: widget.placeholder ?? 'Start typing...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontStyle: FontStyle.italic,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
