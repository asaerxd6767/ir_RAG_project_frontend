import 'package:material_ui/material_ui.dart';

const List<String> _suggestions = <String>[
  'How does a polite crawler behave?',
  'What is TF-IDF used for?',
  'How are web pages deduplicated?',
];

class QuestionComposer extends StatefulWidget {
  const QuestionComposer({
    super.key,
    required this.onSubmit,
    required this.isLoading,
    required this.recentQuestions,
  });

  final Future<void> Function(String question) onSubmit;
  final bool isLoading;
  final List<String> recentQuestions;

  @override
  State<QuestionComposer> createState() => _QuestionComposerState();
}

class _QuestionComposerState extends State<QuestionComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasError = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final question = _controller.text.trim();
    if (question.isEmpty) {
      setState(() => _hasError = true);
      return;
    }
    _focusNode.unfocus();
    await widget.onSubmit(question);
    if (!mounted) return;
    _controller.clear();
    if (_hasError) setState(() => _hasError = false);
  }

  void _useSuggestion(String question) {
    _controller.text = question;
    _hasError = false;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ideas = <String>{..._suggestions, ...widget.recentQuestions}.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.question_answer_rounded, color: scheme.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Ask a question',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onChanged: (value) {
                if (_hasError && value.trim().isNotEmpty) {
                  setState(() => _hasError = false);
                }
              },
              decoration: InputDecoration(
                hintText: 'e.g. How does a polite crawler behave?',
                errorText: _hasError ? 'Write a question before asking.' : null,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.edit_note_rounded),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: widget.isLoading ? null : _submit,
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(widget.isLoading ? 'Retrieving…' : 'Ask the corpus'),
            ),
            const SizedBox(height: 18),
            Text(
              'Try an example',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final idea in ideas)
                  ActionChip(
                    label: Text(idea, style: const TextStyle(fontSize: 12)),
                    onPressed: widget.isLoading ? null : () => _useSuggestion(idea),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
