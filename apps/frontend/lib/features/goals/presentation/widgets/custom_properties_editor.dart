import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class CustomPropertiesEditor extends StatelessWidget {
  final List<dynamic> customProperties;
  final VoidCallback onAddField;
  final Function(int) onMoveUp;
  final Function(int) onMoveDown;
  final Function(dynamic) onEditField;
  final Function(int) onDeleteField;
  final bool isSaving;

  const CustomPropertiesEditor({
    super.key,
    required this.customProperties,
    required this.onAddField,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEditField,
    required this.onDeleteField,
    required this.isSaving,
  });

  String _propertyTypeLabel(dynamic type) {
    final typeName = type.toString().split('.').last;
    switch (typeName) {
      case 'text':
        return 'Text';
      case 'number':
        return 'Number';
      case 'date':
        return 'Date';
      case 'select':
        return 'Select';
      case 'checkbox':
        return 'Checkbox';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TASK FIELDS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: AppPallete.getTextMuted(context),
              ),
            ),
            const Spacer(),
            if (isSaving)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  'Saving...',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPallete.getTextMuted(context),
                  ),
                ),
              ),
            GestureDetector(
              onTap: onAddField,
              child: Icon(
                Icons.add,
                size: 18,
                color: AppPallete.getTextSecondary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (customProperties.isEmpty)
          Text(
            'No custom fields defined.',
            style: TextStyle(
              fontSize: 13,
              color: AppPallete.getTextMuted(context),
            ),
          ),
        ...customProperties.asMap().entries.map((entry) {
          final index = entry.key;
          final property = entry.value;
          return _buildSchemaFieldRow(context, index, property);
        }),
      ],
    );
  }

  Widget _buildSchemaFieldRow(
    BuildContext context,
    int index,
    dynamic property,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppPallete.getSecondarySurface(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppPallete.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _propertyTypeLabel(property.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPallete.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: index > 0 ? () => onMoveUp(index) : null,
            icon: const Icon(Icons.arrow_upward, size: 16),
            tooltip: 'Move up',
          ),
          IconButton(
            onPressed: index < customProperties.length - 1
                ? () => onMoveDown(index)
                : null,
            icon: const Icon(Icons.arrow_downward, size: 16),
            tooltip: 'Move down',
          ),
          IconButton(
            onPressed: () => onEditField(property),
            icon: const Icon(Icons.edit_outlined, size: 16),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => onDeleteField(index),
            icon: const Icon(Icons.delete_outline, size: 16),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
