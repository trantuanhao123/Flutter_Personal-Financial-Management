import 'package:flutter/material.dart';
import 'package:do_an_mobile/models/models.dart';
import 'package:do_an_mobile/services/realm_service.dart';
import 'package:intl/intl.dart';
import '../neon_styles.dart';

class EditTransactionDialog extends StatefulWidget {
  final RealmService realmService;
  final GiaoDich? transaction;
  final Function onSave;

  const EditTransactionDialog({
    super.key,
    required this.realmService,
    this.transaction,
    required this.onSave,
  });

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = '';
  String _selectedType = 'Chi';
  DateTime _selectedDate = DateTime.now();
  List<DanhMuc> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
      _noteController.text = widget.transaction!.note ?? '';
      _selectedCategory = widget.transaction!.category;
      _selectedType = widget.transaction!.type;
      _selectedDate = widget.transaction!.date;
    }
  }

  Future<void> _loadCategories() async {
    final categories = await widget.realmService.getAllCategories();
    setState(() {
      _categories = categories;
      if (_selectedCategory.isEmpty && categories.isNotEmpty) {
        _selectedCategory = categories.first.name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.transaction == null ? 'Thêm giao dịch' : 'Sửa giao dịch'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ['Thu', 'Chi'].map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                    // Reset selected category when type changes
                    _selectedCategory = '';
                  });
                  _loadCategories();
                },
                decoration: const InputDecoration(labelText: 'Loại'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                items: _categories
                    .where((category) => category.type == _selectedType)
                    .map((DanhMuc category) {
                  return DropdownMenuItem<String>(
                    value: category.name,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Danh mục'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn danh mục';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tiền'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final transaction = GiaoDich(
                widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                double.parse(_amountController.text),
                _selectedCategory,
                _selectedDate,
                _selectedType,
                widget.transaction?.isPinned ?? false,
                note: _noteController.text,
              );
              widget.onSave(transaction);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}