import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ProductModel {
  final int? id;
  final String name;
  final String barcode;
  final String expiryDate;

  ProductModel({this.id, required this.name, required this.barcode, required this.expiryDate});

  // تحويل البيانات إلى خريطة (Map) لحفظها في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'expiryDate': expiryDate,
    };
  }

  // تحويل البيانات القادمة من قاعدة البيانات إلى نموذج (Model)
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      expiryDate: map['expiryDate'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('groapp.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE products ( 
  id $idType, 
  name $textType,
  barcode $textType,
  expiryDate $textType
)
''');
  }

  // دالة لإضافة منتج جديد
  Future<int> createProduct(ProductModel product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  // دالة لجلب كل المنتجات
  Future<List<ProductModel>> readAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');

    return result.map((json) => ProductModel.fromMap(json)).toList();
  }

  // دالة لحذف منتج
  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
