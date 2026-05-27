import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/darcula.dart';
import 'package:flutter_highlighter/themes/github.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/chat/presentation/providers/chat_provider.dart';
import 'package:frontend/features/chat/data/models/chat_models.dart';
import 'package:frontend/features/chat/presentation/widgets/action_cards.dart';
import 'package:frontend/features/chat/presentation/widgets/bundle_confirmation_widget.dart';
import 'package:frontend/features/chat/presentation/widgets/follow_up_widget.dart';

/// Standard Chat Bubble for both User and Assistant messages.
class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final Function(String) onSuggestionTap;

  const ChatBubble({
    super.key, 
    required this.message, 
    required this.onSuggestionTap,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Only animate if the message is recent or loading
    final isRecent =
        DateTime.now().difference(widget.message.timestamp).inSeconds < 5;
    if (isRecent || widget.message.isLoading) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isUser = widget.message.isUser;
    final message = widget.message;

    if (message.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const ThinkingIndicator(),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: isUser ? () {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset position = box.localToGlobal(Offset.zero);
                
                showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    position.dx + (isUser ? box.size.width - 100 : 0),
                    position.dy,
                    position.dx,
                    position.dy,
                  ),
                  items: [
                    const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppPallete.errorColor),
                      ),
                    ),
                  ],
                ).then((value) {
                  if (value == 'edit') {
                    _showEditDialog(context, message);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, message);
                  }
                });
              } : null,
              child: Container(
                padding: isUser 
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    : const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                decoration: isUser
                    ? BoxDecoration(
                        color: AppPallete.isDarkMode(context)
                          ? const Color(0xff262626) // Darker, richer grey for dark mode
                          : const Color(0xffebebeb), // More defined grey for light mode
                      borderRadius: BorderRadius.circular(20),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.fragments != null && message.fragments!.isNotEmpty)
                      ...message.fragments!.map((fragment) {
                        if (fragment.type == 'text' && fragment.text != null) {
                          return MarkdownBody(
                            data: fragment.text!,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                color: AppPallete.getTextPrimary(context),
                                fontSize: 16,
                                height: 1.5,
                              ),
                              code: const TextStyle(
                                backgroundColor: Colors.transparent,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: AppPallete.getSurface(context),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: AppPallete.getBorderColor(context)),
                              ),
                            ),
                            builders: {'code': CodeElementBuilder(context)},
                          );
                        } else if (fragment.type == 'object' && fragment.object != null) {
                          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ActionCardFactory(
                              action: fragment.object!,
                              sourceMessageId: message.id,
                              onConfirm: (modifiedAction) {
                                chatProvider.executeConfirmedAction(modifiedAction, message.id);
                              },
                              onCancel: () {},
                              onToggleTask: (taskId, isCompleted) {
                                chatProvider.toggleFocusTask(taskId, isCompleted);
                              },
                              onBatchAction: (actions, sourceId) {
                                chatProvider.executeBatchCardActions(actions, sourceId);
                              },
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      })
                    else ...[
                      MarkdownBody(
                        data: message.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: AppPallete.getTextPrimary(context),
                            fontSize: 16,
                            height: 1.5,
                          ),
                          code: const TextStyle(
                            backgroundColor: Colors.transparent,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: AppPallete.getSurface(context),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: AppPallete.getBorderColor(context)),
                          ),
                        ),
                        builders: {'code': CodeElementBuilder(context)},
                      ),
                      if (message.pendingAction != null)
                        Builder(
                          builder: (context) {
                            final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ActionCardFactory(
                                action: message.pendingAction!,
                                sourceMessageId: message.id,
                                onConfirm: (modifiedAction) {
                                  chatProvider.executeConfirmedAction(modifiedAction, message.id);
                                },
                                onCancel: () {},
                                onToggleTask: (taskId, isCompleted) {
                                  chatProvider.toggleFocusTask(taskId, isCompleted);
                                },
                                onBatchAction: (actions, sourceId) {
                                  chatProvider.executeBatchCardActions(actions, sourceId);
                                },
                              ),
                            );
                          },
                        ),
                      if (message.pendingActions != null && message.pendingActions!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: BundleConfirmationWidget(
                            pendingActions: message.pendingActions!,
                            onConfirm: (confirmedActions) {
                              Provider.of<ChatProvider>(context, listen: false)
                                  .executeBundleActions(confirmedActions, message.id);
                            },
                            onCancel: () {},
                          ),
                        ),
                    ],
                    if (message.followUps != null && message.followUps!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: FollowUpWidget(
                          followUps: message.followUps!,
                          onSuggestionTap: widget.onSuggestionTap,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            color: AppPallete.getTextMuted(context).withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: message.content),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Message copied')),
                              );
                            },
                            child: Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: AppPallete.getTextMuted(context).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ChatMessage message) {
    final textController = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit message'),
          content: TextField(
            controller: textController,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Enter new message',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newContent = textController.text.trim();
                Navigator.pop(context);
                if (newContent.isNotEmpty && newContent != message.content) {
                  Provider.of<ChatProvider>(context, listen: false)
                      .editMessage(message, newContent);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete message'),
          content: const Text(
            'Are you sure you want to delete this message?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Provider.of<ChatProvider>(context, listen: false)
                    .deleteMessage(message.id);
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: AppPallete.getErrorColor(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ChatGPT-style Thinking indicator.
class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = AppPallete.getTextMuted(context).withValues(alpha: 0.4);
    final shimmerColor = AppPallete.getPrimaryColor(context).withValues(alpha: 0.7);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final statusText = chatProvider.currentStatus ?? 'Thinking...';
        
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [baseColor, shimmerColor, baseColor],
                  stops: [
                    (_controller.value - 0.3).clamp(0.0, 1.0),
                    _controller.value,
                    (_controller.value + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: baseColor,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  CodeElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    bool isBlock = element.textContent.contains('\n');
    String language = '';
    if (element.attributes['class']?.startsWith('language-') == true) {
      language = element.attributes['class']!.substring(9);
      isBlock = true;
    }

    if (!isBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppPallete.isDarkMode(context)
              ? Colors.black12
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          element.textContent,
          style: TextStyle(
            fontFamily: 'monospace',
            color: AppPallete.getTextPrimary(context),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: AppPallete.isDarkMode(context)
            ? const Color(0xff2b2b2b)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPallete.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppPallete.isDarkMode(context)
                  ? Colors.grey[900]
                  : Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.isEmpty ? 'code' : language,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.getTextSecondary(context),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: element.textContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                  },
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: AppPallete.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: HighlightView(
              element.textContent,
              language: language.isEmpty ? 'plaintext' : language,
              theme: AppPallete.isDarkMode(context)
                  ? darculaTheme
                  : githubTheme,
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
