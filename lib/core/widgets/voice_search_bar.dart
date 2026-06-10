import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceSearchBar extends StatefulWidget {
  const VoiceSearchBar({
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  State<VoiceSearchBar> createState() => _VoiceSearchBarState();
}

class _VoiceSearchBarState extends State<VoiceSearchBar> {
  final SearchController _controller = SearchController();
  final SpeechToText _speech = SpeechToText();

  bool _isListening = false;

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      hintText: widget.hintText,
      leading: const Icon(Icons.search),
      trailing: [
        IconButton(
          tooltip: _isListening ? 'Stop voice search' : 'Voice search',
          onPressed: _toggleListening,
          icon: Icon(_isListening ? Icons.mic : Icons.mic_none_outlined),
        ),
      ],
      onChanged: widget.onChanged,
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    final available = await _speech.initialize();
    if (!available) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice search is not available.')),
      );
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: 'en_IN'),
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) {
          return;
        }

        _controller.text = words;
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
        widget.onChanged(words);

        if (result.finalResult && mounted) {
          setState(() => _isListening = false);
        }
      },
    );
  }
}
