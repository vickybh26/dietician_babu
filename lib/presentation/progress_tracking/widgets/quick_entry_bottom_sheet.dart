import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class QuickEntryBottomSheet extends StatefulWidget {
  final String entryType;
  final Function(Map<String, dynamic>) onSave;

  const QuickEntryBottomSheet({
    Key? key,
    required this.entryType,
    required this.onSave,
  }) : super(key: key);

  @override
  State<QuickEntryBottomSheet> createState() => _QuickEntryBottomSheetState();
}

class _QuickEntryBottomSheetState extends State<QuickEntryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  String? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    switch (widget.entryType) {
      case 'weight':
        _controllers['weight'] = TextEditingController();
        _selectedUnit = 'kg';
        break;
      case 'measurement':
        _controllers['waist'] = TextEditingController();
        _controllers['chest'] = TextEditingController();
        _controllers['arms'] = TextEditingController();
        _controllers['thighs'] = TextEditingController();
        _selectedUnit = 'cm';
        break;
      case 'activity':
        _controllers['steps'] = TextEditingController();
        _controllers['calories'] = TextEditingController();
        _controllers['duration'] = TextEditingController();
        break;
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6.w),
          topRight: Radius.circular(6.w),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.dividerLight,
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Quick ${widget.entryType.toUpperCase()} Entry',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          Form(
            key: _formKey,
            child: Column(
              children: _buildFormFields(),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveEntry,
                  child: Text('Save'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    switch (widget.entryType) {
      case 'weight':
        return [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _controllers['weight'],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Weight',
                    hintText: 'Enter your weight',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weight';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                  ),
                  items: ['kg', 'lbs'].map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ];
      case 'measurement':
        return _controllers.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: entry.value,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: entry.key.toUpperCase(),
                      hintText: 'Enter ${entry.key} measurement',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.dividerLight),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Text(
                      'cm',
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      case 'activity':
        return [
          TextFormField(
            controller: _controllers['steps'],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Steps',
              hintText: 'Enter steps count',
              suffixText: 'steps',
            ),
          ),
          SizedBox(height: 2.h),
          TextFormField(
            controller: _controllers['calories'],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Calories Burned',
              hintText: 'Enter calories burned',
              suffixText: 'cal',
            ),
          ),
          SizedBox(height: 2.h),
          TextFormField(
            controller: _controllers['duration'],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Duration',
              hintText: 'Enter workout duration',
              suffixText: 'min',
            ),
          ),
        ];
      default:
        return [];
    }
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> entryData = {
        'type': widget.entryType,
        'timestamp': DateTime.now(),
      };

      _controllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          entryData[key] = double.tryParse(controller.text) ?? controller.text;
        }
      });

      if (_selectedUnit != null) {
        entryData['unit'] = _selectedUnit;
      }

      widget.onSave(entryData);
      Navigator.pop(context);
    }
  }
}
