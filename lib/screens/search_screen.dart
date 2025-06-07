import 'package:flutter/material.dart';
import 'package:do_an_mobile/models/models.dart';
import '../services/realm_service.dart';

class SearchScreen extends StatefulWidget {
  final RealmService realmService;

  const SearchScreen({super.key, required this.realmService});

  @override
  State<StatefulWidget> createState() {
    return _SearchScreenState();
  }
}

class _SearchScreenState extends State<SearchScreen> {
  String _typeFilter = 'Tất cả';
  String _categoryFilter = 'Tất cả';
  List<GiaoDich> _filteredTransactions = [];
  List<DanhMuc> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await widget.realmService.getAllCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _search() async {
    final transactions = await widget.realmService.getFilteredTransactions(
      category: _categoryFilter == 'Tất cả' ? null : _categoryFilter,
    );

    setState(() {
      _filteredTransactions = transactions
          .where((t) => _typeFilter == 'Tất cả' || t.type == _typeFilter)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tìm kiếm')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _typeFilter,
                    items: ['Tất cả', 'Thu', 'Chi'].map((String value) {
                      return DropdownMenuItem<String>(
                          value: value, child: Text(value));
                    }).toList(),
                    onChanged: (value) => setState(() => _typeFilter = value!),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _categoryFilter,
                    items: [
                      DropdownMenuItem<String>(
                          value: 'Tất cả', child: Text('Tất cả')),
                      ..._categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.name,
                          child: Text(category.name),
                        );
                      }),
                    ],
                    onChanged: (value) =>
                        setState(() => _categoryFilter = value!),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => _search(),
                child: Text('Tìm kiếm')
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _filteredTransactions[index];
                  return ListTile(
                    title: Text(
                        '${transaction.category}: ${transaction.type == 'Thu' ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} VNĐ'),
                    subtitle: Text(
                        '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}