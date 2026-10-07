import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class CaptchaDialog extends StatefulWidget {
  final Function(int targetId)? onVerify;
  final VoidCallback? onVerifySimple;
  final int? targetId;

  const CaptchaDialog({
    Key? key,
    this.targetId,
    this.onVerify,
    this.onVerifySimple,
  }) : super(key: key);

  @override
  _CaptchaDialogState createState() => _CaptchaDialogState();
}

const List<Map<String, dynamic>> _kDefaultCaptchaCategories = [
  {
    "id": 14,
    "category_name": "Traffic Lights",
    "image": "https://admin.jobes24x7.com/api/uploads/1785136131964_traffic_lights_category.png",
  },
  {
    "id": 11,
    "category_name": "flower",
    "image": "https://admin.jobes24x7.com/api/uploads/1783668547025_flower_category.png",
  },
  {
    "id": 10,
    "category_name": "buildings",
    "image": "https://admin.jobes24x7.com/api/uploads/1783668507489_buildings_category.png",
  },
  {
    "id": 9,
    "category_name": "furniture",
    "image": "https://admin.jobes24x7.com/api/uploads/1783668524791_furniture_category.png",
  },
  {
    "id": 8,
    "category_name": "electronics",
    "image": "https://admin.jobes24x7.com/api/uploads/1783668714082_electronics_category.png",
  },
  {
    "id": 7,
    "category_name": "nature",
    "image": "https://admin.jobes24x7.com/api/uploads/1783668565003_nature_category.png",
  },
  {
    "id": 6,
    "category_name": "clothing",
    "image": "https://admin.jobes24x7.com/api/uploads/1783668575457_clothing_category.png",
  },
  {
    "id": 4,
    "category_name": "food",
    "image": "https://admin.jobes24x7.com/api/uploads/1783668601764_food_category.png",
  },
  {
    "id": 3,
    "category_name": "vehicle",
    "image": "https://admin.jobes24x7.com/api/uploads/1783668622800_vehicle_category.png",
  },
  {
    "id": 2,
    "category_name": "animal",
    "image": "https://admin.jobes24x7.com/api/uploads/1783665540216_animal_category.png",
  },
  {
    "id": 1,
    "category_name": "bird",
    "image": "https://admin.jobes24x7.com/api/uploads/1785136067020_bird_category.png",
  },
];

class _CaptchaDialogState extends State<CaptchaDialog> {
  bool isLoading = true;
  List<dynamic> allCategories = [];
  List<dynamic> displayedImages = [];
  Map<String, dynamic>? targetCategory;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    fetchCaptcha();
  }

  Future<void> fetchCaptcha() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      selectedIndex = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://managelogin.jobes24x7.com/api/outsideapis/captcha/category',
            ),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'EnquiryApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null && (data['data'] as List).isNotEmpty) {
          allCategories = data['data'];
        } else {
          allCategories = List.from(_kDefaultCaptchaCategories);
        }
      } else {
        allCategories = List.from(_kDefaultCaptchaCategories);
      }
    } catch (e) {
      print('Error fetching captcha (using fallback list): $e');
      allCategories = List.from(_kDefaultCaptchaCategories);
    } finally {
      if (mounted) {
        _generateGrid();
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _generateGrid() {
    if (allCategories.isEmpty) return;

    if (widget.targetId != null && widget.targetId != 0) {
      targetCategory = allCategories.firstWhere(
        (cat) => cat['id'] == widget.targetId,
        orElse: () => allCategories[Random().nextInt(allCategories.length)],
      );
    } else {
      targetCategory = allCategories[Random().nextInt(allCategories.length)];
    }

    List<dynamic> gridItems = List.from(allCategories);
    gridItems.shuffle();
    displayedImages = gridItems;
  }

  void _verify() {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image to verify.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedCategory = displayedImages[selectedIndex!];
    if (selectedCategory['id'] == targetCategory?['id']) {
      final int chosenId = targetCategory?['id'] ?? 0;
      Navigator.of(context).pop();
      if (widget.onVerify != null) {
        widget.onVerify!(chosenId);
      } else if (widget.onVerifySimple != null) {
        widget.onVerifySimple!();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect selection. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      fetchCaptcha();
    }
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF47A49B);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 440,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tealColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: tealColor,
                      size: 24,
                    ),
                  ),
                  const Text(
                    "Security Verification",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (targetCategory != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                      ),
                      children: [
                        const TextSpan(text: 'Select the square with '),
                        TextSpan(
                          text: '"${targetCategory!['category_name']}"',
                          style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const TextSpan(text: ' to prove human access'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (isLoading)
                const SizedBox(
                  height: 320,
                  child: Center(
                    child: CircularProgressIndicator(color: tealColor),
                  ),
                )
              else
                SizedBox(
                  height: 340,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: displayedImages.length,
                    itemBuilder: (context, index) {
                      final item = displayedImages[index];
                      final isSelected = selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? tealColor : Colors.grey.shade200,
                              width: isSelected ? 3.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? tealColor.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.04),
                                blurRadius: isSelected ? 6 : 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  item['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        color: Colors.grey.shade100,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                ),
                                if (isSelected)
                                  Container(
                                    color: tealColor.withOpacity(0.25),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  InkWell(
                    onTap: fetchCaptcha,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tealColor,
                        side: const BorderSide(color: Color(0xFFCCFBF1)),
                        backgroundColor: const Color(0xFFF0FDFA),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _verify,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
