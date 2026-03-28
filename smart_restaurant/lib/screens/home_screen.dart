import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/restaurant.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'restaurant_detail_screen.dart';
 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
 
  String _searchQuery = '';
 
  // 🚩 รหัสผ่าน Admin แบบฝังในโค้ด (Static) สามารถแก้ตัวเลขตรงนี้ได้เลยครับ!
  final String _staticAdminPassword = '123';
 
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
 
  void _showAdminLoginDialog() {
    final TextEditingController passwordController = TextEditingController();
 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('เข้าสู่โหมดผู้ดูแลระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('กรุณากรอกรหัสผ่านเพื่อยืนยันตัวตน'),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'รหัสผ่าน Admin',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
              onPressed: () {
                if (passwordController.text == _staticAdminPassword) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ รหัสผ่านไม่ถูกต้อง!'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('🍽️ Smart Restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'สำหรับผู้ดูแลระบบ',
            onPressed: _showAdminLoginDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'ค้นหาร้านอาหาร หรือหมวดหมู่...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
 
          Expanded(
            child: StreamBuilder<List<Restaurant>>(
              stream: _dbService.getRestaurants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('ยังไม่มีร้านอาหารในระบบครับ 😅', style: TextStyle(fontSize: 18)));
                }
 
                List<Restaurant> allRestaurants = snapshot.data!;
 
                List<Restaurant> displayRestaurants = allRestaurants;
                if (_searchQuery.isNotEmpty) {
                  displayRestaurants = allRestaurants.where((r) {
                    return r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           r.category.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();
                }
 
                List<Restaurant> topRestaurants = List.from(allRestaurants)
                  ..sort((a, b) => b.rating.compareTo(a.rating));
                topRestaurants = topRestaurants.take(4).toList();
 
                bool isSearching = _searchQuery.isNotEmpty;
 
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isSearching) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                          child: Text('🔥 ร้านอาหารแนะนำยอดฮิต', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: topRestaurants.length,
                            itemBuilder: (context, index) {
                              return _buildTopRestaurantCard(topRestaurants[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(thickness: 1, indent: 16, endIndent: 16),
                      ],
 
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                        child: Text(
                          isSearching ? '🔍 ผลการค้นหา "${_searchQuery}"' : '🍴 ร้านอาหารทั้งหมด',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                        ),
                      ),
                     
                      if (displayRestaurants.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: Text('ไม่พบร้านอาหารที่คุณค้นหา 😢', style: TextStyle(fontSize: 16, color: Colors.grey))),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: displayRestaurants.length,
                          itemBuilder: (context, index) {
                            return _buildNormalRestaurantCard(displayRestaurants[index]);
                          },
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildTopRestaurantCard(Restaurant restaurant) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // 🚀 เสียบสายไฟ: นำทางไปหน้ารายละเอียดร้าน
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  width: double.infinity,
                  child: restaurant.imageUrl.isNotEmpty
                      ? Image.network(
                          restaurant.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                        )
                      : Container(color: Colors.grey[300], child: const Icon(Icons.restaurant, size: 50, color: Colors.grey)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(restaurant.category, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildNormalRestaurantCard(Restaurant restaurant) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 70,
            height: 70,
            child: restaurant.imageUrl.isNotEmpty
                ? Image.network(
                    restaurant.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                  )
                : Container(color: Colors.grey[300], child: const Icon(Icons.restaurant)),
          ),
        ),
        title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(restaurant.category, style: TextStyle(color: Colors.deepOrange[300])),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${restaurant.rating.toStringAsFixed(1)} คะแนน'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // 🚀 เสียบสายไฟ: นำทางไปหน้ารายละเอียดร้าน
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
            ),
          );
        },
      ),
    );
  }
}