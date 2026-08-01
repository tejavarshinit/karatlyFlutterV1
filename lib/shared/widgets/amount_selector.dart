import 'package:flutter/material.dart';

class AmountSelector extends StatelessWidget {
  final List<int> presets;
  final ValueChanged<int> onSelect;
  final int? value;

  const AmountSelector({
    super.key,
    required this.presets,
    required this.onSelect,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: presets.length,
          itemBuilder: (context, index) {
            final preset = presets[index];
            final isSelected = value == preset;
            return GestureDetector(
              onTap: () => onSelect(preset),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF7CD57).withOpacity(0.2)
                      : const Color(0xFF242320),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF7CD57) : const Color(0xFF3D3B37),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '₹${preset.toString()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFFF7CD57) : Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final num = int.tryParse(val);
            if (num != null) onSelect(num);
          },
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Enter custom amount',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Text('₹', style: TextStyle(color: Color(0xFF9E9A94), fontWeight: FontWeight.w600)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: const Color(0xFF242320),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3D3B37)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3D3B37)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF7CD57), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
