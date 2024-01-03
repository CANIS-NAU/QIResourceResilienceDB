// pdfDownload.dart
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfDownload {
  // function that takes in resource info and creates pdf
  Future<List<int>> generateResourcePdf(
    String name,
    String description,
    String resourceType,
    List<dynamic> privacy,
    int culturalResponsiveness,
    String? fullAddress,
    String? phoneNumber,
    Uri? urlStr,
  ) async {
    try {
      // create a document
      PdfDocument document = PdfDocument();
      // add a page
      final PdfPage page = document.pages.add();
      PdfGrid grid = PdfGrid();
      // set number of columns
      grid.columns.add(count: 2);
      // add a header
      final PdfGridRow headerRow = grid.headers.add(1)[0];
      headerRow.cells[0].value = 'Resource Info';
      headerRow.cells[1].value = 'Values';
      // set header style
      headerRow.style.font = PdfStandardFont(PdfFontFamily.helvetica, 12,
          style: PdfFontStyle.bold);

      // add rows with the resource information
      // TODO: add schedule for events?
      addRow(grid, 'Name', name);
      addRow(grid, 'Description', description);
      addRow(grid, 'Type', resourceType);
      addRow(grid, 'Privacy', privacy.map((e) => e.toString()).join(', '));
      addRow(grid, 'Cultural Responsiveness', culturalResponsiveness);

      if (fullAddress != null) {
        addRow(grid, 'Address', fullAddress);
      }
      if (phoneNumber != null) {
        addRow(grid, 'Phone Number', phoneNumber);
      }
      if (urlStr != null) {
        addRow(grid, 'URL', urlStr);
      }

      // set grid padding
      grid.style.cellPadding = PdfPaddings(left: 5, top: 5);

      // display the grid
      grid.draw(
          page: page,
          bounds: Rect.fromLTWH(0, 0, 0, 0,));
      // save the document
      List<int> pdfBytes = await document.save();

      // dispose the document
      document.dispose();

      return pdfBytes;
    }
    // otherwise print error downloading
    catch (e) {
      print('Error: $e');
      return [];
    }
  }

  // function to download the resource as a pdf
  Future<void> downloadPdf(
      String name,
      String description,
      String resourceType,
      List<dynamic> privacy,
      int culturalResponsiveness,
      String? fullAddress,
      String? phoneNumber,
      Uri? urlStr) async {
    List<int> pdfBytes = await generateResourcePdf(
      name,
      description,
      resourceType,
      privacy,
      culturalResponsiveness,
      fullAddress,
      phoneNumber,
      urlStr,
    );

    html.AnchorElement(
        href: "data:application/pdf;base64, ${base64.encode(pdfBytes)}")
      ..setAttribute("download", name + "-resource.pdf")
      ..click();
  }

  // function to share resource
  Future<void> shareResource (
      String name,
      String description,
      String resourceType,
      List<dynamic> privacy,
      int culturalResponsiveness,
      String? fullAddress,
      String? phoneNumber,
      Uri? urlStr) async {
    List<int> pdfBytes = await generateResourcePdf(
      name,
      description,
      resourceType,
      privacy,
      culturalResponsiveness,
      fullAddress,
      phoneNumber,
      urlStr,
    );

    // convert pdf
    final ByteData bytes = ByteData.view(Uint8List.fromList(pdfBytes).buffer);
    final Uint8List uint8List = bytes.buffer.asUint8List();

    // share pdf
    await Share.shareXFiles(
      [XFile.fromData(uint8List, name: '${name}_resource.pdf')],
      text: '${name} resource attached',
      subject: 'Check out this resource: ${name}'
    );
  }

  // function to add rows to a grid
  void addRow(PdfGrid grid, String label, dynamic value) {
    PdfGridRow row = grid.rows.add();
    row.cells[0].value = label;
    row.cells[1].value = value.toString();
  }
}
