import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'database_helper.dart';

void main() {
  runApp(const GroApp());
}

class GroApp extends StatelessWidget {
  const GroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GROAPP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const ScannerScreen(),
    );
  }
}

// شاشة الكاميرا ومسح الباركود
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false; // لمنع المسح المتكرر لنفس الباركود

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code != null) {
      _isProcessing = true;
      
      // إيقاف الكاميرا مؤقتاً
      await controller.stop();

      // الانتقال لشاشة إدخال البيانات
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddProductScreen(barcode: code),
        ),
      ).then((_) {
        // عند العودة من شاشة الإدخال، نعيد تشغيل الكاميرا
        _isProcessing = false;
        controller.start();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('امسح الباركود'),
        centerTitle: true,
        actions: [
          // زر الذهاب لقائمة المنتجات
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProductsListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // مستطيل التوضيح في منتصف الشاشة
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// شاشة إدخال بيانات المنتج بعد المسح
class AddProductScreen extends StatefulWidget {
  final String barcode;
  const AddProductScreen({super.key, required this.barcode});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _db = DatabaseHelper.instance;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      String formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _dateController.text = formattedDate;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المنتج والتاريخ')),
      );
      return;
    }

    final product = ProductModel(
      name: _nameController.text,
      barcode: widget.barcode,
      expiryDate: _dateController.text,
    );

    await _db.createProduct(product);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ المنتج بنجاح!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل المنتج'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.qr_code),
                title: Text('الباركود: ${widget.barcode}'),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _selectDate,
              decoration: const InputDecoration(
                labelText: 'تاريخ الانتهاء',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProduct,
                child: const Text('حفظ المنتج'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// الشاشة الرئيسية لعرض قائمة المنتجات
class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final _db = DatabaseHelper.instance;

  // دالة لحساب اللون حسب التاريخ
  Color _getProductColor(String expiryDate) {
    DateTime expiry = DateTime.parse(expiryDate);
    DateTime now = DateTime.now();
    int daysLeft = expiry.difference(now).inDays;

    if (daysLeft <= 30) {
      return Colors.red; // أقل من شهر
    } else if (daysLeft <= 90) {
      return Colors.amber; // أقل من 3 شهور
    } else {
      return Colors.green; // طبيعي
    }
  }

  Future<void> _deleteProduct(int id) async {
    // نافذة إدخال كلمة المرور
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'أدخل كلمة المرور',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                if (passwordController.text == '1234') {
                  await _db.deleteProduct(id);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  setState(() {}); // تحديث القائمة بعد الحذف
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المنتج بنجاح')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('كلمة المرور غير صحيحة!')),
                  );
                }
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة المنتجات'),
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _db.readAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد منتجات مسجلة بعد'));
          }

          final products = snapshot.data!;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final color = _getProductColor(product.expiryDate);

              return Card(
                color: color.withOpacity(0.2), // لون خلفية فاتح حسب الحالة
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: const Icon(Icons.inventory_2, color: Colors.white),
                  ),
                  title: Text(product.name),
                  subtitle: Text('تاريخ الانتهاء: ${product.expiryDate}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProduct(product.id!),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
