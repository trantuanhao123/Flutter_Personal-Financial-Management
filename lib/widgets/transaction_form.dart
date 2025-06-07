import 'package:flutter/material.dart';
import 'package:do_an_mobile/models/models.dart';
import '../services/realm_service.dart';
import '../neon_styles.dart';

class TransactionForm extends StatefulWidget {
  final RealmService realmService;
  const TransactionForm({super.key, required this.realmService});
  @override
  State<StatefulWidget> createState() {
    return _TransactionFormState();
  }
}

class _TransactionFormState extends State<TransactionForm> {
  final _amountController = TextEditingController();
  String? _type;
  DanhMuc? _category;
  final _formKey = GlobalKey<FormState>();
  List<DanhMuc> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final categories = await widget.realmService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải danh mục: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thuCategories = _categories.where((c) => c.type == 'Thu').toList();
    final chiCategories = _categories.where((c) => c.type == 'Chi').toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: NeonStyles.neonCard(),
              child: TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Số tiền'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: NeonStyles.neonCard(),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Loại giao dịch'),
                value: _type,
                items: <String>['Thu', 'Chi'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _type = newValue;
                    _category = null; // Reset danh mục khi đổi loại
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn loại giao dịch';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_type == 'Thu')
              Container(
                decoration: NeonStyles.neonCard(),
                child: DropdownButtonFormField<DanhMuc>(
                  decoration: const InputDecoration(labelText: 'Danh mục thu'),
                  value: _category,
                  items: thuCategories.map((DanhMuc category) {
                    return DropdownMenuItem<DanhMuc>(
                      value: category,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (DanhMuc? newValue) {
                    setState(() {
                      _category = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Vui lòng chọn danh mục thu';
                    }
                    return null;
                  },
                ),
              ),
            if (_type == 'Chi')
              Container(
                decoration: NeonStyles.neonCard(),
                child: DropdownButtonFormField<DanhMuc>(
                  decoration: const InputDecoration(labelText: 'Danh mục chi'),
                  value: _category,
                  items: chiCategories.map((DanhMuc category) {
                    return DropdownMenuItem<DanhMuc>(
                      value: category,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (DanhMuc? newValue) {
                    setState(() {
                      _category = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Vui lòng chọn danh mục chi';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 16),
            Container(
              decoration: NeonStyles.neonCard(),
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _category != null && _type != null) {
                    final amount = double.parse(_amountController.text);
                    final newTransaction = GiaoDich(
                      DateTime.now().millisecondsSinceEpoch.toString(),
                      amount,
                      _category!.name,
                      DateTime.now(),
                      _type!,
                      false,
                    );
                    
                    await widget.realmService.addTransaction(newTransaction);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}