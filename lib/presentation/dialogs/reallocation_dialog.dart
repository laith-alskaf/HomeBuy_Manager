import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../utils/formatters.dart';

class ReallocationDialog extends StatefulWidget {
  final String targetCategoryName;
  final double requiredAmount;
  final double availableInTarget;
  final Map<String, double> availableSources; // Key: CategoryID, Value: Remaining Balance
  final Map<String, dynamic> categoriesConfig;

  const ReallocationDialog({
    super.key,
    required this.targetCategoryName,
    required this.requiredAmount,
    required this.availableInTarget,
    required this.availableSources,
    required this.categoriesConfig,
  });

  @override
  State<ReallocationDialog> createState() => _ReallocationDialogState();
}

class _ReallocationDialogState extends State<ReallocationDialog> {
  String? _selectedSource;

  @override
  Widget build(BuildContext context) {
    final deficit = widget.requiredAmount - widget.availableInTarget;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
           Icon(Icons.warning_amber_rounded, color: AppColors.danger),
           SizedBox(width: 10),
           Text('تجاوز الميزانية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رصيد "${widget.targetCategoryName}" لا يكفي لإتمام العملية.',
            style: const TextStyle(color: AppColors.textDark),
          ),
          const SizedBox(height: 15),
          _buildInfoRow('المتوفر:', formatCurrency(widget.availableInTarget), Colors.green),
          _buildInfoRow('المطلوب:', formatCurrency(widget.requiredAmount), Colors.black),
          _buildInfoRow('العجز:', formatCurrency(deficit), AppColors.danger),
          const SizedBox(height: 20),
          const Text('نقل الأموال من:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          if (widget.availableSources.isEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Text('لا توجد فئات أخرى بها فائض كافٍ.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedSource,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('اختر فئة بها فائض'),
              items: widget.availableSources.entries.map((entry) {
                final catName = widget.categoriesConfig[entry.key]?['label'] ?? entry.key;
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(catName, style: const TextStyle(fontSize: 13)),
                      Text(
                        ' (متبقي: ${formatCurrency(entry.value)})',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedSource = val),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null), // Cancel
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _selectedSource == null
              ? null
              : () {
                  Navigator.pop(context, _selectedSource); // Return selected source ID
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('نقل ومتابعة', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}