import 'package:flutter/material.dart';
import 'package:realm/realm.dart'; // Thêm import Realm
import 'screens/home_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/report_screen.dart';
import 'services/realm_service.dart';
import 'neon_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final realmService = RealmService();
  await realmService.initialize();

  runApp(MyApp(realmService: realmService));
}

class MyApp extends StatelessWidget {
  final RealmService realmService;

  const MyApp({super.key, required this.realmService});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: NeonStyles.silkGalaxyGradient(),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ứng dụng Quản lý Tài chính Cá nhân',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Color(0xFF181A20),
          fontFamily: 'Montserrat',
          primaryColor: Color(0xFF00FFC6), // Neon xanh
          colorScheme: ColorScheme.dark(
            primary: Color(0xFF00FFC6),
            secondary: Color(0xFF00B4D8),
            background: Color(0xFF181A20),
            surface: Color(0xFF232526),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
            titleLarge: TextStyle(color: Color(0xFF00FFC6), fontWeight: FontWeight.bold),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF00FFC6)),
            titleTextStyle: TextStyle(
              color: Color(0xFF00FFC6),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00FFC6),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF00FFC6),
            foregroundColor: Colors.black,
          ),
        ),
        home: MainScreen(realmService: realmService),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final RealmService realmService;

  const MainScreen({super.key, required this.realmService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(realmService: widget.realmService),
      TransactionScreen(realmService: widget.realmService),
      BudgetScreen(realmService: widget.realmService),
      ReportScreen(realmService: widget.realmService),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    widget.realmService.close(); // Đóng Realm khi thoát app
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: NeonStyles.neonGalaxyGradient(),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
              activeIcon: Icon(Icons.home_rounded, size: 28),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sync_alt_rounded),
              label: 'Giao dịch',
              activeIcon: Icon(Icons.sync_alt_rounded, size: 28),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Ngân sách',
              activeIcon: Icon(Icons.account_balance_wallet_rounded, size: 28),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Báo cáo',
              activeIcon: Icon(Icons.bar_chart_rounded, size: 28),
            ),
          ],
          currentIndex: _selectedIndex,
          backgroundColor: Colors.transparent,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
