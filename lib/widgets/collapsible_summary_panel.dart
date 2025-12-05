import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CollapsibleSummaryPanel extends StatefulWidget {
  final String summary;
  final String? translation;
  final String originalText;
  final bool isLoading;
  final String? error;
  final VoidCallback? onSummarize;
  final Function(String)? onTranslate;

  const CollapsibleSummaryPanel({
    super.key,
    required this.summary,
    this.translation,
    required this.originalText,
    this.isLoading = false,
    this.error,
    this.onSummarize,
    this.onTranslate,
  });

  @override
  State<CollapsibleSummaryPanel> createState() =>
      _CollapsibleSummaryPanelState();
}

class _CollapsibleSummaryPanelState extends State<CollapsibleSummaryPanel> {
  bool _isExpanded = false;
  bool _showTranslation = false;
  String _selectedLanguage = 'Hindi';
  final List<String> _languages = ['Hindi', 'Spanish', 'French'];

  int get _originalWordCount =>
      widget.originalText.trim().split(RegExp(r'\s+')).length;
  int get _summaryWordCount =>
      widget.summary.trim().split(RegExp(r'\s+')).length;

  Future<void> _copyToClipboard() async {
    final textToCopy = _showTranslation
        ? (widget.translation ?? '')
        : widget.summary;
    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_showTranslation ? "Translation" : "Summary"} copied to clipboard',
          ),
        ),
      );
    }
  }

  Future<void> _shareSummary() async {
    final textToShare = _showTranslation
        ? (widget.translation ?? '')
        : widget.summary;
    await Share.share(textToShare);
  }

  Future<void> _downloadSummary() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final type = _showTranslation ? 'translation' : 'summary';
      final file = File(
        '${directory.path}/${type}_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      final textToSave = _showTranslation
          ? (widget.translation ?? '')
          : widget.summary;
      await file.writeAsString(textToSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_showTranslation ? "Translation" : "Summary"} saved to ${file.path}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.summarize, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Page Summary & Translation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (widget.summary.isNotEmpty && !widget.isLoading)
                          Text(
                            '$_originalWordCount -> $_summaryWordCount words',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _isExpanded ? Icons.expand_more : Icons.expand_less,
                      color: Colors.grey,
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (widget.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${widget.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (widget.summary.isEmpty && !widget.isLoading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ElevatedButton(
                    onPressed: widget.onSummarize,
                    child: const Text('Generate Summary'),
                  ),
                ),
              )
            else if (widget.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Language Selection and Toggle
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _selectedLanguage,
                          items: _languages.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedLanguage = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (widget.onTranslate != null) {
                              widget.onTranslate!(_selectedLanguage);
                              setState(() {
                                _showTranslation = true;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Translate'),
                        ),
                        const Spacer(),
                        if (widget.translation != null)
                          Row(
                            children: [
                              const Text('Show Translation'),
                              Switch(
                                value: _showTranslation,
                                onChanged: (value) {
                                  setState(() {
                                    _showTranslation = value;
                                  });
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: _showTranslation && widget.translation != null
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Summary',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.summary,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const VerticalDivider(width: 32),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Translation ($_selectedLanguage)',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.translation!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                widget.summary,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: Icons.copy,
                          label: 'Copy',
                          onTap: _copyToClipboard,
                        ),
                        _ActionButton(
                          icon: Icons.download,
                          label: 'Download',
                          onTap: _downloadSummary,
                        ),
                        _ActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          onTap: _shareSummary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
