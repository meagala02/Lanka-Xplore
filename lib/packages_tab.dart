import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PackagesTab extends StatefulWidget {
  const PackagesTab({super.key});

  @override
  State<PackagesTab> createState() => _PackagesTabState();
}

class _PackagesTabState extends State<PackagesTab> {
  XFile? _pickedFile;
  int? _hoveredIndex;

  Future<void> _pickImage(StateSetter setST) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setST(() => _pickedFile = picked);
    }
  }

  Future<String> _uploadToStorage(XFile file) async {
    try {
      String fileName = 'pkg_${DateTime.now().millisecondsSinceEpoch}';
      Reference ref =
          FirebaseStorage.instance.ref().child('package_images/$fileName');
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(await file.readAsBytes());
      } else {
        uploadTask = ref.putFile(File(file.path));
      }
      TaskSnapshot snap = await uploadTask;
      return await snap.ref.getDownloadURL();
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");
      return "";
    }
  }

  void _deletePackage(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title:
            const Text("Delete Package", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this package?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('packages')
                  .doc(id)
                  .delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Package deleted"),
                    backgroundColor: Colors.redAccent),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TRAVEL PACKAGES",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.5)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black),
                onPressed: () => _showPackageForm(),
                icon: const Icon(Icons.add),
                label: const Text("ADD PACKAGE",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Table Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2128),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(60),
              1: FixedColumnWidth(60),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.2),
              5: FlexColumnWidth(1.2),
              6: FlexColumnWidth(1.5),
              7: FixedColumnWidth(100),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.white10, width: 1)),
                ),
                children: [
                  _headerCell("#"),
                  _headerCell("IMG"),
                  _headerCell("NAME"),
                  _headerCell("TYPE"),
                  _headerCell("LOCATION"),
                  _headerCell("DURATION"),
                  _headerCell("BUDGET"),
                  _headerCell("ACTIONS"),
                ],
              )
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('packages')
                .orderBy('updatedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text("Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.redAccent)));
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent));
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161B22),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text("No packages found. Add your first package!",
                          style: TextStyle(color: Colors.white38)),
                    ),
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF161B22),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                child: StatefulBuilder(
                  builder: (context, setTableState) {
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'Unnamed';
                        final type = data['type'] ?? '-';
                        final location = data['location'] ?? '-';
                        final duration = data['duration'] ?? '-';
                        final budget = data['budget'] ?? '-';
                        final imageUrl = data['imageUrl'] ?? '';
                        final pkgId = data['packageId'] ??
                            'P${(index + 1).toString().padLeft(3, '0')}';

                        final isHovered = _hoveredIndex == index;

                        return MouseRegion(
                          onEnter: (_) => setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          child: GestureDetector(
                            onTap: () => _showPackageForm(doc: doc),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? const Color(0xFF1C2B2B)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isHovered
                                        ? Colors.tealAccent
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  bottom: const BorderSide(
                                      color: Colors.white10, width: 0.5),
                                ),
                              ),
                              child: Table(
                                columnWidths: const {
                                  0: FixedColumnWidth(60),
                                  1: FixedColumnWidth(60),
                                  2: FlexColumnWidth(2),
                                  3: FlexColumnWidth(1.5),
                                  4: FlexColumnWidth(1.2),
                                  5: FlexColumnWidth(1.2),
                                  6: FlexColumnWidth(1.5),
                                  7: FixedColumnWidth(100),
                                },
                                children: [
                                  TableRow(children: [
                                    // Row number
                                    _dataCell(
                                      Text(
                                        pkgId,
                                        style: TextStyle(
                                            color: isHovered
                                                ? Colors.tealAccent
                                                : Colors.white38,
                                            fontSize: 11),
                                      ),
                                    ),

                                    // Image
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 6),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                width: 42,
                                                height: 42,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _defaultImage(),
                                              )
                                            : _defaultImage(),
                                      ),
                                    ),

                                    // Name
                                    _dataCell(Text(name,
                                        style: TextStyle(
                                            color: isHovered
                                                ? Colors.white
                                                : Colors.white70,
                                            fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis)),

                                    // Type
                                    _dataCell(_typeBadge(type)),

                                    // Location
                                    _dataCell(Text(location,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12),
                                        overflow: TextOverflow.ellipsis)),

                                    // Duration
                                    _dataCell(Text(_shortDuration(duration),
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12),
                                        overflow: TextOverflow.ellipsis)),

                                    // Budget
                                    _dataCell(Text(_shortBudget(budget),
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12),
                                        overflow: TextOverflow.ellipsis)),

                                    // Actions
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            tooltip: "Edit",
                                            icon: const Icon(Icons.edit,
                                                color: Colors.tealAccent,
                                                size: 18),
                                            onPressed: () =>
                                                _showPackageForm(doc: doc),
                                          ),
                                          IconButton(
                                            tooltip: "Delete",
                                            icon: const Icon(Icons.delete,
                                                color: Colors.redAccent,
                                                size: 18),
                                            onPressed: () =>
                                                _deletePackage(doc.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _defaultImage() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.landscape, color: Colors.tealAccent, size: 20),
    );
  }

  Widget _typeBadge(String type) {
    final colors = {
      'adventure': Colors.orange,
      'beach': Colors.blue,
      'cultural': Colors.purple,
      'nature': Colors.green,
    };
    final color = colors[type.toLowerCase()] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(type,
          style: TextStyle(color: color, fontSize: 11),
          overflow: TextOverflow.ellipsis),
    );
  }

  String _shortDuration(String dur) {
    if (dur.contains('day trip')) return '1 Day';
    if (dur.contains('weekend')) return '2-3 Days';
    if (dur.contains('long')) return '7+ Days';
    return dur;
  }

  String _shortBudget(String budget) {
    if (budget.contains('budget')) return 'Rs 20k-30k';
    if (budget.contains('medium')) return 'Rs 50k-80k';
    if (budget.contains('premium')) return 'Rs 100k+';
    return budget;
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(text,
          style: const TextStyle(
              color: Colors.tealAccent,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1)),
    );
  }

  Widget _dataCell(Widget child) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: child);
  }

  // ===================== PACKAGE FORM =====================
  void _showPackageForm({DocumentSnapshot? doc}) {
    final nameCtrl = TextEditingController(
        text: doc != null ? (doc.data() as Map)['name'] ?? '' : '');
    final descCtrl = TextEditingController(
        text: doc != null ? (doc.data() as Map)['description'] ?? '' : '');

    String type = 'adventure';
    String budget = 'budget Rs20000-30000';
    String loc = 'Colombo';
    String dur = 'day trip 1 day';

    if (doc != null) {
      final d = doc.data() as Map;
      type = d['type'] ?? 'adventure';
      budget = d['budget'] ?? 'budget Rs20000-30000';
      loc = d['location'] ?? 'Colombo';
      dur = d['duration'] ?? 'day trip 1 day';
    }

    _pickedFile = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setST) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom,
              top: 30,
              left: 25,
              right: 25),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(doc == null ? "ADD NEW PACKAGE" : "EDIT PACKAGE",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () => Navigator.pop(ctx2),
                  )
                ],
              ),
              const SizedBox(height: 15),

              // Image Picker
              GestureDetector(
                onTap: () => _pickImage(setST),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                  ),
                  child: _pickedFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: kIsWeb
                              ? Image.network(_pickedFile!.path,
                                  fit: BoxFit.cover)
                              : Image.file(File(_pickedFile!.path),
                                  fit: BoxFit.cover))
                      : (doc != null &&
                              (doc.data() as Map)['imageUrl'] != null &&
                              (doc.data() as Map)['imageUrl'] != "")
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                        (doc.data() as Map)['imageUrl'],
                                        fit: BoxFit.cover)),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit,
                                            color: Colors.tealAccent, size: 16),
                                        SizedBox(width: 6),
                                        Text("Change Image",
                                            style: TextStyle(
                                                color: Colors.tealAccent,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    color: Colors.tealAccent, size: 40),
                                SizedBox(height: 8),
                                Text("Tap to add image",
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 13)),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 5),

              _formField(nameCtrl, "Package Name *"),
              _dropdownField(
                  "Type",
                  type,
                  ['adventure', 'beach', 'cultural', 'nature'],
                  (v) => setST(() => type = v!)),
              _formField(descCtrl, "Description *", maxLines: 3),
              _dropdownField(
                  "Budget",
                  budget,
                  [
                    'budget Rs20000-30000',
                    'mediumRs50000-80000',
                    'premiumRs100000-200000'
                  ],
                  (v) => setST(() => budget = v!)),
              _dropdownField(
                  "Location",
                  loc,
                  [
                    'Colombo',
                    'Gampaha',
                    'Kalutara',
                    'Kandy',
                    'Matale',
                    'Nuwara Eliya',
                    'Galle',
                    'Matara',
                    'Hambantota',
                    'Jaffna',
                    'Kilinochchi',
                    'Mannar',
                    'Vavuniya',
                    'Mullaitivu',
                    'Batticaloa',
                    'Ampara',
                    'Trincomalee',
                    'Kurunegala',
                    'Puttalam',
                    'Anuradhapura',
                    'Polonnaruwa',
                    'Badulla',
                    'Moneragala',
                    'Ratnapura',
                    'Kegalle'
                  ],
                  (v) => setST(() => loc = v!)),
              _dropdownField(
                  "Duration",
                  dur,
                  [
                    'day trip 1 day',
                    'weekend trip 2-3 days',
                    'long vacation 7+ days'
                  ],
                  (v) => setST(() => dur = v!)),

              const SizedBox(height: 25),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  // Validate required text fields
                  if (nameCtrl.text.trim().isEmpty) {
                    _showFieldError(ctx2, "Please fill the Package Name field");
                    return;
                  }
                  if (descCtrl.text.trim().isEmpty) {
                    _showFieldError(ctx2, "Please fill the Description field");
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Saving... Please wait"),
                      duration: Duration(seconds: 2)));

                  try {
                    String finalImageUrl = doc != null
                        ? (doc.data() as Map)['imageUrl'] ?? ""
                        : "";

                    if (_pickedFile != null) {
                      finalImageUrl = await _uploadToStorage(_pickedFile!);
                    }

                    // Generate package ID
                    String packageId;
                    if (doc != null) {
                      packageId = (doc.data() as Map)['packageId'] ?? 'P001';
                    } else {
                      final count = await FirebaseFirestore.instance
                          .collection('packages')
                          .get();
                      packageId =
                          'P${(count.docs.length + 1).toString().padLeft(3, '0')}';
                    }

                    final data = {
                      'packageId': packageId,
                      'name': nameCtrl.text.trim(),
                      'type': type,
                      'description': descCtrl.text.trim(),
                      'budget': budget,
                      'location': loc,
                      'duration': dur,
                      'imageUrl': finalImageUrl,
                      'updatedAt': Timestamp.now(),
                    };

                    if (doc == null) {
                      data['createdAt'] = Timestamp.now();
                      await FirebaseFirestore.instance
                          .collection('packages')
                          .add(data);
                    } else {
                      await doc.reference.update(data);
                    }

                    Navigator.pop(ctx2);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Saved Successfully!"),
                        backgroundColor: Colors.green));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Save Failed: $e"),
                        backgroundColor: Colors.red));
                  }
                },
                child: const Text("SAVE PACKAGE",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              const SizedBox(height: 30),
            ]),
          ),
        );
      }),
    );
  }

  void _showFieldError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3)));
  }

  Widget _formField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.tealAccent, width: 1.5)),
        ),
      ),
    );
  }

  Widget _dropdownField(String label, String value, List<String> items,
      Function(String?) onChange) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((i) => DropdownMenuItem(
                value: i,
                child: Text(i, style: const TextStyle(color: Colors.white))))
            .toList(),
        onChanged: onChange,
        dropdownColor: const Color(0xFF1C2128),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.tealAccent),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.tealAccent, width: 1.5)),
        ),
      ),
    );
  }
}
