import 'package:flutter/material.dart';

import '../../config/theme.dart';

class MemoCard extends StatelessWidget {
  final String memoId;
  final String date;
  final String from;
  final String subject;
  final String recipients;
  final VoidCallback onTap;
  final String body;

  const MemoCard({
    super.key,
    required this.memoId,
    required this.date,
    required this.from,
    required this.subject,
    required this.recipients,
    required this.onTap,
    this.body = '',
  });

  @override
  Widget build(BuildContext context) {
    // Format the memo ID by removing leading zeroes
    final String formattedMemoId = memoId.replaceFirst(RegExp('^0+'), '');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with memo number and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Memorandum No. $formattedMemoId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Subject line
              Text(
                subject.isEmpty ? 'No Subject' : subject,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // From line
              Text(
                'From: ${from.isEmpty ? 'Unknown Sender' : from}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              // To line
              Text(
                'To: $recipients',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              // Body preview
            ],
          ),
        ),
      ),
    );
  }
}
