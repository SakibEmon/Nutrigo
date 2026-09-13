import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'health_report_service.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  bool _loading = true;
  Uint8List? _pdfBytes;

  final List<String> _months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _pdfBytes = null;
    });

    try {
      final bytes = await HealthReportService.generateMonthlyPdf(
        year: _selectedYear,
        month: _selectedMonth,
      );

      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Report Generation Error: $e");
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error preparing report: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    try {
      final fileName =
          "Nutrigo_Report_${_months[_selectedMonth - 1]}_$_selectedYear.pdf";
      await Printing.layoutPdf(
        name: fileName,
        format: PdfPageFormat.a4,
        onLayout: (PdfPageFormat format) async => _pdfBytes!,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to download: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    try {
      final fileName =
          "Nutrigo_Report_${_months[_selectedMonth - 1]}_$_selectedYear.pdf";
      await Printing.sharePdf(bytes: _pdfBytes!, filename: fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to share: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),
      appBar: AppBar(
        title: Text(
          "Monthly Health Report",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff2E7D32),
                      side: const BorderSide(
                        color: Color(0xff2E7D32),
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: _loading || _pdfBytes == null
                        ? null
                        : _downloadPdf,
                    icon: const Icon(Icons.download_rounded, size: 19),
                    label: Text(
                      "Download",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2E7D32),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: _loading || _pdfBytes == null ? null : _sharePdf,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      "Share",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xffF1F8E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffC8E6C9)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        isExpanded: true,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              _months[index],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMonth = val);
                            _loadReport();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF1F8E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffC8E6C9)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      items:
                          [
                            DateTime.now().year - 1,
                            DateTime.now().year,
                            DateTime.now().year + 1,
                          ].map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text(
                                "$y",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                          _loadReport();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xff2E7D32)),
                        SizedBox(height: 12),
                        Text("Preparing report..."),
                      ],
                    ),
                  )
                : _pdfBytes == null
                ? Center(
                    child: Text(
                      "Failed to render document.",
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                : PdfPreview(
                    key: ValueKey("pdf-$_selectedMonth-$_selectedYear"),
                    build: (format) => _pdfBytes!,
                    useActions: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    maxPageWidth: 650,
                  ),
          ),
        ],
      ),
    );
  }
}
