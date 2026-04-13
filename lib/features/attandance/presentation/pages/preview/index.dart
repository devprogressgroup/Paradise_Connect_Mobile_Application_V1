import 'dart:io';
import 'package:flutter/material.dart';

class PreviewImageWidget extends StatelessWidget {
  final File image;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  const PreviewImageWidget({
    super.key,
    required this.image,
    required this.onRetake,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 🖼️ IMAGE
        Positioned.fill(
          child: Image.file(
            image,
            fit: BoxFit.cover,
          ),
        ),

        /// 🔥 ACTION BUTTON
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: onRetake,
                child: const Text("Retake"),
              ),
              ElevatedButton(
                onPressed: onUse,
                child: const Text("Use"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}