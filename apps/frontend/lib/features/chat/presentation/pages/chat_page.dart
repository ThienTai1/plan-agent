import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/chat/presentation/providers/chat_provider.dart';
import 'package:frontend/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:frontend/features/premium/presentation/widgets/paywall_bottom_sheet.dart';

class ChatPage extends StatefulWidget {
  static const String routeName = '/chat';

  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).init();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Check quota BEFORE sending to provide immediate premium feedback
    final quota = chatProvider.quotaStatus;
    final isLimitReached = !chatProvider.isPro && quota.aiCredits <= 0;
    
    if (isLimitReached) {
      PaywallBottomSheet.show(context);
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await chatProvider.sendMessage(text);

    // Scroll to bottom after message
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      drawer: Drawer(
        backgroundColor: AppPallete.getBackgroundColor(context),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Conversation History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.getTextPrimary(context),
                  ),
                ),
              ),
              const Divider(),
              // History items
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    if (chatProvider.threads.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No conversation history.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppPallete.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chatProvider.threads.length,
                      itemBuilder: (context, index) {
                        final thread = chatProvider.threads[index];
                        final isToday =
                            thread.updatedAt.day == DateTime.now().day &&
                            thread.updatedAt.month == DateTime.now().month &&
                            thread.updatedAt.year == DateTime.now().year;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index == 0 ||
                                (isToday &&
                                    chatProvider
                                            .threads[index - 1]
                                            .updatedAt
                                            .day !=
                                        DateTime.now().day)) ...[
                              Text(
                                isToday ? 'Today' : 'Older',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppPallete.getTextSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            _HistoryItem(
                              id: thread.id,
                              title: thread.title ?? 'New Chat',
                              time: DateFormat(
                                'hh:mm a',
                              ).format(thread.updatedAt),
                              onTap: () {
                                Navigator.pop(context); // Close drawer
                                chatProvider.init(thread.id);
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.add,
                  color: AppPallete.getPrimaryColor(context),
                ),
                title: Text(
                  'New chat',
                  style: TextStyle(color: AppPallete.getPrimaryColor(context)),
                ),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  ).clearMessages(); // Start a fresh conversation view
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: AppPallete.getTextPrimary(context)),
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            String title = 'New Chat';
            if (chatProvider.currentThreadId != null) {
              final threadIndex = chatProvider.threads.indexWhere(
                (t) => t.id == chatProvider.currentThreadId,
              );
              if (threadIndex != -1) {
                title = chatProvider.threads[threadIndex].title ?? 'New Chat';
              }
            }
            return Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppPallete.getTextPrimary(context),
              ),
            );
          },
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.history,
                color: AppPallete.getTextSecondary(context),
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Chat history',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.messages.isEmpty) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 80.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 120), // Compensate for removed elements
                          Text(
                            'Hello! I am Levigo AI, your strategic planning companion.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppPallete.getTextPrimary(context),
                              height: 1.4,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'How can I assist you today?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppPallete.getTextSecondary(context),
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Clean Quick Actions
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildActionChip(
                                context,
                                label: 'Plan my day',
                                icon: LucideIcons.calendar_check,
                                color: const Color(0xFF10B981),
                              ),
                              _buildActionChip(
                                context,
                                label: 'Break down goal',
                                icon: LucideIcons.target,
                                color: const Color(0xFF6C4DDA),
                              ),
                              _buildActionChip(
                                context,
                                label: 'Progress report',
                                icon: LucideIcons.chart_bar,
                                color: const Color(0xFF00B4D8),
                              ),
                              _buildActionChip(
                                context,
                                label: 'Suggest priorities',
                                icon: LucideIcons.lightbulb,
                                color: const Color(0xFFFFB300),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms);
                }


                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return ChatBubble(
                      message: message,
                      onSuggestionTap: (suggestion) {
                        _messageController.text = suggestion;
                        _sendMessage();
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 2. Usage indicator for free users
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.isPro) return const SizedBox.shrink();

              final quota = chatProvider.quotaStatus;
              String usageText = '';
              bool isWarning = false;

              if (quota.aiCredits > 0) {
                usageText = '${quota.aiCredits}/20 trial messages left';
                isWarning = quota.aiCredits <= 3;
              } else {
                usageText = 'Trial ended. Upgrade to Pro for unlimited chat! 🚀';
                isWarning = true;
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 16,
                ),
                alignment: Alignment.centerRight,
                child: Text(
                  usageText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isWarning
                        ? AppPallete.errorColor
                        : AppPallete.getTextMuted(context),
                  ),
                ),
              );
            },
          ),

          // 3. Input area with Limit Handling
          Container(
            decoration: BoxDecoration(
              color: AppPallete.getSurface(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppPallete.isDarkMode(context) ? 0.2 : 0.05,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final quota = chatProvider.quotaStatus;
                // Limit is reached if Trial Credits exhausted for free users
                final isLimitReached = !chatProvider.isPro && quota.aiCredits <= 0;

                if (isLimitReached) {
                  return InkWell(
                    onTap: () => PaywallBottomSheet.show(context),
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppPallete.getPrimaryColor(context),
                              AppPallete.getPrimaryColor(context).withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.sparkles,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Trial Version Ended',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Go Pro for unlimited planning potential',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevron_right,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return child!;
              },
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppPallete.getSecondarySurface(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppPallete.getBorderColor(context),
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppPallete.getTextPrimary(context),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: AppPallete.getTextMuted(context),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Consumer<ChatProvider>(
                        builder: (context, chatProvider, _) {
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: chatProvider.isGenerating
                                  ? AppPallete.errorColor
                                  : AppPallete.getPrimaryColor(context),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              icon: chatProvider.isGenerating
                                  ? const Icon(
                                      Icons.stop_rounded,
                                      color: Colors.white,
                                    )
                                  : chatProvider.isLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppPallete.isDarkMode(context)
                                                  ? AppPallete
                                                        .darkBackgroundColor
                                                  : Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.send,
                                      color: AppPallete.isDarkMode(context)
                                          ? AppPallete.darkBackgroundColor
                                          : Colors.white,
                                    ),
                              onPressed: chatProvider.isGenerating
                                  ? () => chatProvider.stopGenerating()
                                  : chatProvider.isLoading
                                  ? null
                                  : _sendMessage,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(String action) {
    _messageController.text = action;
    _sendMessage();
  }

  Widget _buildActionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleQuickAction(label),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String id;
  final String title;
  final String time;
  final VoidCallback onTap;

  const _HistoryItem({
    required this.id,
    required this.title,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPallete.getSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppPallete.getBorderColor(context).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppPallete.getTextPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPallete.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 16,
                color: AppPallete.getTextSecondary(context),
              ),
              onSelected: (value) {
                if (value == 'rename') {
                  final textController = TextEditingController(text: title);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Rename chat'),
                        content: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: 'Enter new name',
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              final newTitle = textController.text.trim();
                              if (newTitle.isNotEmpty) {
                                Provider.of<ChatProvider>(
                                  context,
                                  listen: false,
                                ).renameThread(id, newTitle);
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                } else if (value == 'delete') {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete chat'),
                        content: const Text(
                          'Are you sure you want to delete this chat?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Provider.of<ChatProvider>(
                                context,
                                listen: false,
                              ).deleteThread(id);
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
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'rename',
                  child: Text('Rename'),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppPallete.errorColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
