import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:magtapp/bloc/ai/ai_bloc.dart';
import 'package:magtapp/bloc/ai/ai_event.dart';
import 'package:magtapp/bloc/ai/ai_state.dart';

class AIAssistantWidget extends StatefulWidget {
  final String? currentUrl;
  final Future<String> Function()? onGetPageContent;

  const AIAssistantWidget({super.key, this.currentUrl, this.onGetPageContent});

  @override
  State<AIAssistantWidget> createState() => _AIAssistantWidgetState();
}

class _AIAssistantWidgetState extends State<AIAssistantWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSummarize() async {
    if (widget.onGetPageContent != null) {
      final content = await widget.onGetPageContent!();
      if (mounted) {
        context.read<AIBloc>().add(
          AISummarizePage(content, widget.currentUrl ?? ''),
        );
      }
    }
  }

  Future<void> _handleTranslate() async {
    if (widget.onGetPageContent != null) {
      final content = await widget.onGetPageContent!();
      if (mounted) {
        context.read<AIBloc>().add(
          AITranslatePage(content, 'Hindi', widget.currentUrl ?? ''),
        ); // Default to Hindi for now
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Summary'),
              Tab(text: 'Translate'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryView(context),
                _buildTranslateView(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _handleSummarize,
                icon: const Icon(Icons.summarize),
                label: const Text('Summarize Page'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildResultArea()),
        ],
      ),
    );
  }

  Widget _buildTranslateView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _handleTranslate,
            icon: const Icon(Icons.translate),
            label: const Text('Translate Page to Hindi'),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildResultArea()),
        ],
      ),
    );
  }

  Widget _buildResultArea() {
    return BlocBuilder<AIBloc, AIState>(
      builder: (context, state) {
        if (state.status == AIStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state.status == AIStatus.failure) {
          return Center(child: Text('Error: ${state.error}'));
        } else if (state.status == AIStatus.success && state.result != null) {
          return SingleChildScrollView(
            child: MarkdownBody(data: state.result!),
          );
        } else {
          return const Center(child: Text('No results yet.'));
        }
      },
    );
  }
}
