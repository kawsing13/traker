import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
        elevation: elevation ?? 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          side:
              borderSide ?? BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        color: backgroundColor ?? Colors.white,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

// A specialized version for form items in lists
class FormItemCard extends StatelessWidget {
  final String formNumber;
  final String? dateFiled;
  final String? dateApplied;
  final String formType;
  final String status;
  final VoidCallback onTap;
  final List<Widget>? extraContent;

  const FormItemCard({
    super.key,
    required this.formNumber,
    this.dateFiled,
    this.dateApplied,
    required this.formType,
    required this.status,
    required this.onTap,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    final isVoided = status.toUpperCase() == 'VOIDED';
    final isFinalized = status.toUpperCase() != 'NOT SUBMITTED' && !isVoided;
    final isApproved = status.toUpperCase() == 'APPROVED';
    final isRejected = status.toUpperCase() == 'REJECTED';

    Color statusColor;
    if (isVoided) {
      statusColor = Colors.grey;
    } else if (isRejected) {
      statusColor = AppTheme.dangerColor;
    } else if (isApproved) {
      statusColor = AppTheme.successColor;
    } else if (isFinalized) {
      statusColor = AppTheme.infoColor;
    } else {
      statusColor = Colors.black;
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Form No. $formNumber',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Date Filed:', dateFiled ?? 'Pending'),
            if (dateApplied != null)
              _buildInfoRow('Date Applied:', dateApplied!),
            _buildInfoRow('Type:', formType),
            _buildInfoRow(
              'Status:',
              status,
              isBold: true,
              textColor: statusColor,
            ),
            if (extraContent != null) ...extraContent!,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: textColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A new reusable form field display for read-only fields
class FormField extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiline;

  const FormField({
    super.key,
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade50,
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              maxLines: isMultiline ? null : 1,
            ),
          ),
        ],
      ),
    );
  }
}
