import 'package:realm/realm.dart';
import 'package:uuid/uuid.dart' as uuid; // Thêm import cho Uuid
import '../models/models.dart';

class RealmService {
  static final RealmService _instance = RealmService._internal();
  factory RealmService() => _instance;

  late Realm? _realm;
  bool isInitialized = false;
  final _uuid = const uuid.Uuid();

  RealmService._internal();

  Future<void> initialize() async {
    if (isInitialized) return;

    final config = Configuration.local([DanhMuc.schema, GiaoDich.schema]);
    
    // Delete old database file
    try {
      Realm.deleteRealm(config.path);
    } catch (e) {
      // Ignore error if file doesn't exist
    }
    
    _realm = Realm(config);
    isInitialized = true;

    await initializeDefaultCategories();
  }

  Future<void> saveCategories(List<DanhMuc> categories) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    _realm!.write(() {
      _realm!.deleteAll<DanhMuc>();
      for (var category in categories) {
        _realm!.add(category);
      }
    });
  }

  Future<List<DanhMuc>> loadCategories() async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    final results = _realm!.all<DanhMuc>();
    return results.toList();
  }

  Future<void> saveTransactions(List<GiaoDich> transactions) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    _realm!.write(() {
      _realm!.deleteAll<GiaoDich>();
      for (var transaction in transactions) {
        _realm!.add(transaction);
      }
    });
  }
  Future<void> pinTransaction(GiaoDich transaction) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    final existingTransaction = _realm!.find<GiaoDich>(transaction.id);
    if (existingTransaction != null) {
      _realm!.write(() {
        existingTransaction.isPinned = !existingTransaction.isPinned;
      });
    } else {
      throw Exception('Không tìm thấy giao dịch với ID: ${transaction.id}');
    }
  }

  Future<List<GiaoDich>> loadTransactions() async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    final results = _realm!.all<GiaoDich>();
    return results.toList();
  }

  Future<void> addTransaction(GiaoDich transaction) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    _realm!.write(() {
      _realm!.add(transaction);
    });
  }

  Future<void> updateTransaction(
    String transactionId, {
    String? newCategory,
    double? newAmount,
    DateTime? newDate,
    String? newType,
    String? newNote,
  }) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    final existingTransaction = _realm!.find<GiaoDich>(transactionId);
    if (existingTransaction != null) {
      _realm!.write(() {
        if (newCategory != null) existingTransaction.category = newCategory;
        if (newAmount != null) existingTransaction.amount = newAmount;
        if (newDate != null) existingTransaction.date = newDate;
        if (newType != null) existingTransaction.type = newType;
        if (newNote != null) existingTransaction.note = newNote;
      });
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    final transaction = _realm!.find<GiaoDich>(id);
    if (transaction != null) {
      _realm!.write(() {
        _realm!.delete(transaction);
      });
    }
  }

  Future<void> addCategory(DanhMuc category) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    // Set default values if null
    if (category.icon == null) category.icon = "more_horiz";
    if (category.color == null) category.color = "#9E9E9E";

    _realm!.write(() {
      _realm!.add(category);
    });
  }

  Future<void> deleteCategory(String categoryName) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }
    final category = _realm!.all<DanhMuc>().where((c) => c.name == categoryName).firstOrNull;
    if (category != null) {
      // Tìm hoặc tạo DanhMuc 'Khác'
      DanhMuc? otherCategory = _realm!.all<DanhMuc>().where((c) => c.name == 'Khác').firstOrNull;
      if (otherCategory == null) {
        otherCategory = DanhMuc(
          _uuid.v4(),
          'Khác',
          category.type,
        );
        _realm!.write(() {
          _realm!.add(otherCategory!);
        });
      }
      // Cập nhật tất cả GiaoDich liên quan
      final transactions = _realm!.all<GiaoDich>().where((t) => t.category == categoryName);
      _realm!.write(() {
        for (final t in transactions) {
          if (otherCategory != null) {
            t.category = otherCategory.name;
          }
        }
        _realm!.delete(category);
      });
    }
  }

  Future<void> clear() async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    _realm!.write(() {
      _realm!.deleteAll<DanhMuc>();
      _realm!.deleteAll<GiaoDich>();
    });
  }

  Future<void> initializeDefaultCategories() async {
    final categories = await loadCategories();
    if (categories.isEmpty) {
      final defaultCategories = [
        _createDefaultCategory(
          name: "Ăn uống",
          type: "Chi",
          icon: "restaurant",
          color: "orange",
          limit: 2000000,
        ),
        
        _createDefaultCategory(
          name: "Di chuyển",
          type: "Chi",
          icon: "directions_car", 
          color: "blue",
          limit: 1000000,
        ),
        
        _createDefaultCategory(
          name: "Mua sắm",
          type: "Chi",
          icon: "shopping_bag",
          color: "pink",
          limit: 3000000,
        ),
        
        _createDefaultCategory(
          name: "Giải trí",
          type: "Chi",
          icon: "sports_esports",
          color: "purple",
          limit: 1000000,
        ),
        
        _createDefaultCategory(
          name: "Hóa đơn",
          type: "Chi",
          icon: "receipt_long",
          color: "red",
          limit: 2000000,
        ),
        
        _createDefaultCategory(
          name: "Khác",
          type: "Chi",
          icon: "more_horiz",
          color: "grey",
        ),
        
        _createDefaultCategory(
          name: "Lương",
          type: "Thu",
          icon: "account_balance_wallet",
          color: "green",
        ),
        
        _createDefaultCategory(
          name: "Thưởng",
          type: "Thu",
          icon: "card_giftcard",
          color: "amber",
        ),
        
        _createDefaultCategory(
          name: "Đầu tư",
          type: "Thu",
          icon: "trending_up",
          color: "blue",
        ),
        
        _createDefaultCategory(
          name: "Bán hàng",
          type: "Thu",
          icon: "store",
          color: "orange",
        ),
        
        _createDefaultCategory(
          name: "Khác",
          type: "Thu",
          icon: "more_horiz",
          color: "grey",
        ),
      ];

      for (var category in defaultCategories) {
        await addCategory(category);
      }
    }
  }

  // Helper method to create a DanhMuc with proper initialization
  DanhMuc _createDefaultCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
    double? limit,
  }) {
    final category = DanhMuc(
      _uuid.v4(), // id
      name,      // name
      type,      // type
    );
    
    // Đặt các giá trị tùy chọn
    if (icon != null) {
      category.icon = icon;
    }
    if (color != null) {
      category.color = color;
    }
    if (limit != null) {
      category.limit = limit;
    }
    return category;
  }

  void dispose() {
    _realm?.close();
    _realm = null; // Đặt lại _realm để có thể khởi tạo lại nếu cần
    isInitialized = false;
  }

  // Lấy tất cả giao dịch
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    // Lấy tất cả giao dịch và sắp xếp theo thời gian mới nhất
    final transactions = _realm!.all<GiaoDich>()
      .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Lấy danh sách danh mục
    final categories = _realm!.all<DanhMuc>().toList();

    // Chuyển đổi thành dữ liệu hiển thị
    final result = transactions.take(5).map((transaction) {
      // Tìm thông tin danh mục
      final category = categories.firstWhere(
        (c) => c.id == transaction.category,
        orElse: () => DanhMuc(
          'unknown',
          'Không xác định',
          transaction.type,
          icon: 'help_outline',
          color: '#9E9E9E',
        ),
      );

      return {
        'category': category.name,
        'amount': transaction.amount,
        'date': transaction.date,
        'type': transaction.type,
        'icon': category.icon ?? 'help_outline',
        'color': category.color ?? '#9E9E9E',
      };
    }).toList();

    return result;
  }

  // Lấy tất cả danh mục
  Future<List<DanhMuc>> getAllCategories() async {
    return await loadCategories();
  }

  // Lấy tổng thu/chi trong tháng
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final transactions = await loadTransactions();
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.date.year == year && t.date.month == month) {
        if (t.type == 'Thu') income += t.amount;
        else expense += t.amount;
      }
    }
    return {'income': income, 'expense': expense};
  }

  // Lấy giao dịch theo bộ lọc
  Future<List<GiaoDich>> getFilteredTransactions({DateTime? startDate, DateTime? endDate, String? category}) async {
    final transactions = await loadTransactions();
    return transactions.where((t) {
      final matchCategory = category == null || t.category == category;
      final matchStart = startDate == null || t.date.isAfter(startDate.subtract(const Duration(days: 1)));
      final matchEnd = endDate == null || t.date.isBefore(endDate.add(const Duration(days: 1)));
      return matchCategory && matchStart && matchEnd;
    }).toList();
  }

  // Đóng Realm
  void close() {
    dispose();
  }

  Future<void> updateCategory(DanhMuc category) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }
    _realm!.write(() {
      _realm!.add(category, update: true);
    });
  }

  // Đánh dấu giao dịch là quan trọng
  Future<void> toggleTransactionPin(String transactionId) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    final transaction = _realm!.find<GiaoDich>(transactionId);
    if (transaction != null) {
      _realm!.write(() {
        transaction.isPinned = !transaction.isPinned;
      });
    }
  }

  // Kiểm tra giới hạn chi tiêu của một danh mục trong tháng
  Future<Map<String, dynamic>> checkSpendingLimit(String categoryName, int year, int month) async {
    if (_realm == null) {
      throw Exception('Realm chưa được khởi tạo. Gọi initialize() trước.');
    }

    // Lấy danh mục
    final category = _realm!.all<DanhMuc>().where((c) => c.name == categoryName && c.type == 'Chi').firstOrNull;
    if (category == null || category.limit == null) {
      return {'isOverLimit': false, 'currentSpending': 0.0, 'limit': 0.0};
    }

    // Tính tổng chi tiêu trong tháng cho danh mục này
    double totalSpending = 0;
    final transactions = _realm!.all<GiaoDich>().where((t) => 
      t.category == categoryName && 
      t.type == 'Chi' &&
      t.date.year == year &&
      t.date.month == month
    );

    for (var transaction in transactions) {
      totalSpending += transaction.amount;
    }

    return {
      'isOverLimit': totalSpending > category.limit!,
      'currentSpending': totalSpending,
      'limit': category.limit,
    };
  }
}