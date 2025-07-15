import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Ganti image_picker ke file_picker, lebih universal
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/sidebar.dart';

class ManajemenProdukPage extends StatefulWidget {
  final String userId;
  final String userRole;

  const ManajemenProdukPage({
    super.key,
    required this.userId,
    required this.userRole,
  }); // ⬅️ Tambah ini

  @override
  State<ManajemenProdukPage> createState() => _ManajemenProdukPageState();
}


class _ManajemenProdukPageState extends State<ManajemenProdukPage> {
  List<dynamic> products = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final data = await Supabase.instance.client.from('product').select();
    setState(() {
      products = data;
    });
  }

  void showProductDialog({Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final quantityController = TextEditingController(text: product?['quantity']?.toString() ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final satuanController = TextEditingController(text: product?['satuan']?.toString() ?? '');
    final deskripsiController = TextEditingController(text: product?['deskripsi'] ?? '');
    final imageController = TextEditingController(text: product?['image_url'] ?? '');

    String selectedJenis = product?['jenis'] ?? jenisOptions.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.image);
                      if (result != null && result.files.single.bytes != null) {
                        final fileBytes = result.files.single.bytes!;
                        final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.png';

                        // Upload ke Supabase Storage
                        await Supabase.instance.client.storage
                            .from('product-images')
                            .uploadBinary(fileName, fileBytes, fileOptions: const FileOptions(upsert: true));

                        final publicUrl = Supabase.instance.client.storage
                            .from('product-images')
                            .getPublicUrl(fileName);

                        setState(() {
                          imageController.text = publicUrl;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: imageController.text.isNotEmpty
                          ? NetworkImage(imageController.text)
                          : null,
                      child: imageController.text.isEmpty ? const Icon(Icons.camera_alt) : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Produk'),
                  ),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Harga'),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedJenis,
                    items: jenisOptions.map((jenis) {
                      return DropdownMenuItem(
                        value: jenis,
                        child: Text(jenis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedJenis = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Jenis Produk'),
                  ),
                  TextField(
                    controller: satuanController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Satuan'),
                  ),
                  TextField(
                    controller: deskripsiController,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final data = {
                    'name': nameController.text,
                    'quantity': int.tryParse(quantityController.text) ?? 0,
                    'price': int.tryParse(priceController.text) ?? 0,
                    'jenis': selectedJenis,
                    'satuan': int.tryParse(satuanController.text) ?? 0,
                    'deskripsi': deskripsiController.text,
                    'image_url': imageController.text,
                  };

                  if (product == null) {
                    await Supabase.instance.client.from('product').insert(data);
                  } else {
                    await Supabase.instance.client
                        .from('product')
                        .update(data)
                        .eq('id', product['id']);
                  }

                  Navigator.pop(context);
                  fetchProducts();
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> deleteProduct(String id) async {
    await Supabase.instance.client.from('product').delete().eq('id', id);
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Produk')),
      drawer: AdminSidebar(userId: widget.userId, userRole: widget.userRole),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => showProductDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Produk'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(child: Text('Tidak ada produk'))
                  : ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Card(
                          child: ListTile(
                            leading: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(product['image_url']),
                                  )
                                : const CircleAvatar(child: Icon(Icons.image)),
                            title: Text(product['name'] ?? ''),
                            subtitle: Text('Rp ${product['price']} - Stok: ${product['quantity']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => showProductDialog(product: product),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deleteProduct(product['id']),
                                ),
                              ],
                            ),
                          ),
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

const List<String> jenisOptions = [
  'Material Konstruksi',
  'Material Finishing',
  'Material Kayu & Olahan',
  'Material Atap',
  'Peralatan Bangunan',
  'Listrik & Elektrikal',
  'Pipa & Plumbing',
];
