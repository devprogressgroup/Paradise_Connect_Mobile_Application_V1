import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/features/inbox/data/arguments/inbox_detail_args.dart';
import 'package:progress_group/features/inbox/data/models/message_model.dart';

class InboxDetailPage extends StatefulWidget {
  final InboxDetailArgs args;
  const InboxDetailPage({super.key, required this.args});

  @override
  State<InboxDetailPage> createState() => _InboxDetailPageState();
}

class _InboxDetailPageState extends State<InboxDetailPage> {

  final List<MessageModel> messages = [
    MessageModel(
      name: "John Doe",
      message: "Hi, Evan! Nice to meet you tooI will send you all the files I have for this project. After that, we can call and discuss. I will answer all your questions! OK?",
      time: "12:00",
      image: "https://i.pravatar.cc/150?img=1",
    ),
    MessageModel(
      name: "Jane Smith",
      message: "Hi, Oscar! Nice to meet youWe will work with new prject together",
      time: "12:00",
      image: "https://i.pravatar.cc/150?img=1",
    ),
    MessageModel(
      name: "John Doe",
      message: "Hi! Please, change the status in this task",
      time: "12:00",
      image: "https://i.pravatar.cc/150?img=1",
    ),
    MessageModel(
      name: "Jane Smith",
      message: "Hai",
      time: "12:00",
      image: "https://i.pravatar.cc/150?img=1",
    ),
  ];

  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Column( // ❗ FIX: langsung Column
        children: [
          /// HEADER
          Container(
            color: Color(whiteColor),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Icon(Icons.arrow_back,
                      color: Color(primaryColor), size: 27),
                ),
                const SizedBox(width: 10),

                /// 🔥 FIX overflow header
                Expanded(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.args.data.image,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(grey1Color),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(widget.args.icon,
                                color: Color(blue3Color)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      /// 🔥 biar gak overflow ke kanan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.args.data.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              widget.args.data.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// CHAT CONTAINER
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(whiteColor),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Color(shadowColor).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  /// DATE
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Color(grey1Color)),
                    ),
                    child: Text(
                      "Friday, September 8",
                      style: TextStyle(color: Color(grey2Color)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// LIST CHAT
                  Expanded(
                    child: ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  message.image,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Color(grey1Color),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.person,
                                        color: Color(blue3Color)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              /// 🔥 biar text turun & gak overflow
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message.message,
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}