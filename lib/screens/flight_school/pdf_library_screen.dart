import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../../services/auth_service_manager.dart';
import '../../repositories/local_pdf_repository.dart';
import '../../models/pdf_record.dart';
import 'package:intl/intl.dart';

/// PDF Library screen for flight school admins
class PdfLibraryScreen extends StatefulWidget {
  const PdfLibraryScreen({Key? key}) : super(key: key);

  @override
  State<PdfLibraryScreen> createState() => _PdfLibraryScreenState();
}

class _PdfLibraryScreenState extends State<PdfLibraryScreen> {
  final _authService = AuthServiceManager();
  final _pdfRepo = LocalPdfRepository();
  final _searchController = TextEditingController();
  
  List<PdfRecord> _pdfs = [];
  List<PdfRecord> _filteredPdfs = [];
  bool _loading = true;
  String? _selectedPdfType;

  final List<String> _pdfTypes = [
    'All Types',
    'weight_balance',
    'tech_log',
    'fuel_uplift',
    'departure_briefing',
    'passenger_brief',
    'pave_assessment',
  ];

  @override
  void initState() {
    super.initState();
    _loadPdfs();
    _searchController.addListener(_filterPdfs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfs() async {
    setState(() => _loading = true);
    
    try {
      await _pdfRepo.init();
      
      final flightSchoolId = _authService.flightSchoolId;
      if (flightSchoolId != null) {
        final pdfs = await _pdfRepo.getPdfsByFlightSchool(flightSchoolId);
        setState(() {
          _pdfs = pdfs;
          _filteredPdfs = pdfs;
        });
      }
    } catch (e) {
      print('Error loading PDFs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDFs: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterPdfs() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredPdfs = _pdfs.where((pdf) {
        // Filter by search query
        final matchesSearch = query.isEmpty ||
            pdf.title.toLowerCase().contains(query) ||
            (pdf.pilotName?.toLowerCase().contains(query) ?? false) ||
            (pdf.aircraftType?.toLowerCase().contains(query) ?? false) ||
            (pdf.aircraftRegistration?.toLowerCase().contains(query) ?? false);
        
        // Filter by PDF type
        final matchesType = _selectedPdfType == null ||
            _selectedPdfType == 'All Types' ||
            pdf.pdfType == _selectedPdfType;
        
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  String _formatPdfType(String type) {
    return type.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PDF Library',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPdfs,
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by pilot, aircraft, or title...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedPdfType,
                  decoration: InputDecoration(
                    labelText: 'Filter by Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _pdfTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == 'All Types' ? type : _formatPdfType(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPdfType = value;
                    });
                    _filterPdfs();
                  },
                ),
              ],
            ),
          ),
          
          // Results count
          if (!_loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredPdfs.length} PDF${_filteredPdfs.length == 1 ? '' : 's'} found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          
          // PDF list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPdfs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPdfs.length,
                        itemBuilder: (context, index) {
                          return _buildPdfCard(_filteredPdfs[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _pdfs.isEmpty
                ? 'No PDFs uploaded yet'
                : 'No PDFs match your search',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _pdfs.isEmpty
                ? 'PDFs generated by pilots will appear here'
                : 'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCard(PdfRecord pdf) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openPdf(pdf),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pdf.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatPdfType(pdf.pdfType),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, pdf),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new, size: 20),
                            SizedBox(width: 8),
                            Text('Open'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (pdf.pilotName != null) ...[
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      pdf.pilotName!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (pdf.aircraftType != null) ...[
                    Icon(Icons.flight, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${pdf.aircraftType}${pdf.aircraftRegistration != null ? ' (${pdf.aircraftRegistration})' : ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(pdf.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPdf(PdfRecord pdf) async {
    try {
      final file = File(pdf.localPath);
      if (await file.exists()) {
        await OpenFile.open(pdf.localPath);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF file not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e')),
        );
      }
    }
  }

  Future<void> _handleMenuAction(String action, PdfRecord pdf) async {
    if (action == 'open') {
      await _openPdf(pdf);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete PDF'),
          content: Text('Are you sure you want to delete "${pdf.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        try {
          await _pdfRepo.deletePdf(pdf.id);
          await _loadPdfs();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF deleted successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting PDF: $e')),
            );
          }
        }
      }
    }
  }
}
