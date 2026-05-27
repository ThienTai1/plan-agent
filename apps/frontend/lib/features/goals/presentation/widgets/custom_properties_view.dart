import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

enum PropertyType { text, number, date, select, checkbox }

class CustomProperty {
  final String id;
  final String name;
  final PropertyType type;
  dynamic value;
  final List<String>? options; // For select type

  CustomProperty({
    required this.id,
    required this.name,
    required this.type,
    this.value,
    this.options,
  });
}

class CustomPropertiesView extends StatelessWidget {
  final List<CustomProperty> properties;
  final Function(CustomProperty) onPropertyAdded;
  final Function(CustomProperty, dynamic) onValueChanged;

  const CustomPropertiesView({
    super.key,
    required this.properties,
    required this.onPropertyAdded,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...properties.map((prop) => _buildPropertyRow(context, prop)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showAddPropertySheet(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppPallete.getPrimaryColor(
                  context,
                ).withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
              color: AppPallete.getPrimaryColor(
                context,
              ).withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 16,
                  color: AppPallete.getPrimaryColor(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Property',
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.getPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyRow(BuildContext context, CustomProperty prop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon based on type
          Icon(
            _getIconForType(prop.type),
            size: 16,
            color: AppPallete.getTextMuted(context),
          ),
          const SizedBox(width: 8),
          // Property Name
          SizedBox(
            width: 100,
            child: Text(
              prop.name,
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: AppPallete.getTextSecondary(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Property Value (Editable)
          Expanded(child: _buildValueInput(context, prop)),
        ],
      ),
    );
  }

  Widget _buildValueInput(BuildContext context, CustomProperty prop) {
    switch (prop.type) {
      case PropertyType.text:
      case PropertyType.number:
        return GestureDetector(
          onTap: () => _showEditValueSheet(context, prop),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppPallete.getBackgroundColor(context),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              prop.value?.toString() ?? 'Empty',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: prop.value == null
                    ? AppPallete.getTextMuted(context)
                    : AppPallete.getTextPrimary(context),
              ),
            ),
          ),
        );
      case PropertyType.select:
        return Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: prop.value as String?,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppPallete.getPrimaryColor(context),
              ),
              style: TextStyle(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.w500,
                color: AppPallete.getPrimaryColor(context),
              ),
              items: prop.options?.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onValueChanged(prop, newValue);
                }
              },
            ),
          ),
        );
      case PropertyType.date:
        return GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: prop.value as DateTime? ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null) {
              onValueChanged(prop, picked);
            }
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppPallete.getBackgroundColor(context),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppPallete.getTextSecondary(context),
                ),
                const SizedBox(width: 8),
                Text(
                  prop.value != null
                      ? (prop.value as DateTime).toString().split(' ')[0]
                      : 'Select Date',
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppPallete.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        );
      case PropertyType.checkbox:
        return Row(
          children: [
            Switch(
              value: prop.value as bool? ?? false,
              activeTrackColor: AppPallete.getPrimaryColor(context),
              onChanged: (bool newValue) {
                onValueChanged(prop, newValue);
              },
            ),
            Text(
              (prop.value as bool? ?? false) ? 'Yes' : 'No',
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: AppPallete.getTextPrimary(context),
              ),
            ),
          ],
        );
    }
  }

  IconData _getIconForType(PropertyType type) {
    switch (type) {
      case PropertyType.text:
        return Icons.text_fields;
      case PropertyType.number:
        return Icons.numbers;
      case PropertyType.date:
        return Icons.calendar_today;
      case PropertyType.select:
        return Icons.list;
      case PropertyType.checkbox:
        return Icons.toggle_on;
    }
  }

  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppPallete.getTextMuted(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  void _showAddPropertySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String name = '';
        PropertyType selectedType = PropertyType.text;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppPallete.getBackgroundColor(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDragHandle(context),
                    const SizedBox(height: 20),
                    Text(
                      'Add Property',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      style: TextStyle(color: AppPallete.getTextPrimary(context)),
                      decoration: InputDecoration(
                        hintText: 'Property Name',
                        hintStyle: TextStyle(color: AppPallete.getTextMuted(context)),
                        filled: true,
                        fillColor: AppPallete.getSecondarySurface(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppPallete.getSecondarySurface(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PropertyType>(
                          value: selectedType,
                          isExpanded: true,
                          style: TextStyle(color: AppPallete.getTextPrimary(context)),
                          onChanged: (PropertyType? newValue) {
                            setDialogState(() {
                              selectedType = newValue!;
                            });
                          },
                          items: PropertyType.values.map((PropertyType type) {
                            return DropdownMenuItem<PropertyType>(
                              value: type,
                              child: Text(type.toString().split('.').last),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPallete.getPrimaryColor(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (name.isNotEmpty) {
                            final newProp = CustomProperty(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: name,
                              type: selectedType,
                              value: null,
                              options: selectedType == PropertyType.select
                                  ? ['Option 1', 'Option 2']
                                  : null,
                            );
                            onPropertyAdded(newProp);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Add Property', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditValueSheet(BuildContext context, CustomProperty prop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final controller = TextEditingController(
          text: prop.value?.toString() ?? '',
        );
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppPallete.getBackgroundColor(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDragHandle(context),
                const SizedBox(height: 20),
                Text(
                  'Edit ${prop.name}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: AppPallete.getTextPrimary(context)),
                  keyboardType: prop.type == PropertyType.number
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Enter value',
                    hintStyle: TextStyle(color: AppPallete.getTextMuted(context)),
                    filled: true,
                    fillColor: AppPallete.getSecondarySurface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.getPrimaryColor(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final raw = controller.text.trim();
                      if (prop.type == PropertyType.number) {
                        onValueChanged(prop, num.tryParse(raw));
                      } else {
                        onValueChanged(prop, raw.isEmpty ? null : raw);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Save Change', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
