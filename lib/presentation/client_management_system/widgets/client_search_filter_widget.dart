import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientSearchFilterWidget extends StatelessWidget {
  final String searchQuery;
  final String selectedFilter;
  final Function(String) onSearchChanged;
  final Function(String) onFilterChanged;

  const ClientSearchFilterWidget({
    super.key,
    required this.searchQuery,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search clients by name or email...',
                hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () => onSearchChanged(''),
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1976D2)),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedFilter,
                hint: Text(
                  'Filter by',
                  style: GoogleFonts.inter(color: Colors.grey[500]),
                ),
                items: [
                  'All',
                  'This Week',
                  'This Month',
                  'Active Subscriptions',
                  'Expired Subscriptions',
                  'High Value Clients',
                ].map((filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(
                        filter,
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onFilterChanged(value);
                  }
                },
                icon: Icon(Icons.filter_list, color: Colors.grey[600]),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Date Range Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.date_range, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Date Range',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}