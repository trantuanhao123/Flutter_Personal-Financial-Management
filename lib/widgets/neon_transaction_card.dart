import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NeonTransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onPin;
  final bool isPinned;

  const NeonTransactionCard({
    super.key,
    required this.transaction,
    required this.currencyFormat,
    required this.onEdit,
    required this.onPin,
    required this.isPinned,
  });

  IconData _getCategoryIcon(String categoryName, bool isExpense) {
    // Convert string icon name to IconData
    switch (categoryName.toLowerCase()) {
      case 'ăn uống': return Icons.restaurant;
      case 'di chuyển': return Icons.directions_car;
      case 'mua sắm': return Icons.shopping_bag;
      case 'giải trí': return Icons.sports_esports;
      case 'hóa đơn': return Icons.receipt_long;
      case 'lương': return Icons.account_balance_wallet;
      case 'thưởng': return Icons.card_giftcard;
      case 'đầu tư': return Icons.trending_up;
      case 'bán hàng': return Icons.store;
      case 'khác': return Icons.more_horiz;
      default: return Icons.help_outline;
    }
  }

  Color _getCategoryColor(String categoryName, bool isExpense) {
    // Get color based on category name
    switch (categoryName.toLowerCase()) {
      case 'ăn uống': return Colors.orange;
      case 'di chuyển': return Colors.blue;
      case 'mua sắm': return Colors.pink;
      case 'giải trí': return Colors.purple;
      case 'hóa đơn': return Colors.red;
      case 'lương': return Colors.green;
      case 'thưởng': return Colors.amber;
      case 'đầu tư': return Colors.blue;
      case 'bán hàng': return Colors.orange;
      case 'khác': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction['type'] == 'Chi';
    final categoryName = transaction['category'] as String;
    final categoryIcon = _getCategoryIcon(categoryName, isExpense);
    final categoryColor = _getCategoryColor(categoryName, isExpense);
    final amount = transaction['amount'] as double;
    final date = transaction['date'] as DateTime;
    final note = transaction['note'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            categoryName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${isExpense ? '-' : '+'} ${currencyFormat.format(amount)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                          if (note != null && note.isNotEmpty)
                            Text(
                              note,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Pin Button
                IconButton(
                  icon: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isPinned ? categoryColor : Colors.grey,
                    size: 20,
                  ),
                  onPressed: onPin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 