// pdfDownload.dart
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfDownload {
  // function that takes in resource info and creates pdf
  Future<void> printResourceInfo(
      String name,
      String description,
      String resourceType,
      List<dynamic> privacy,
      int culturalResponsiveness,
      String fullAddress,
      String phoneNumber,
      Uri urlStr,

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
      headerRow.style.font =
          PdfStandardFont(
              PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);

      // add rows with the resource information
      addRow(grid, 'Name', name);
      addRow(grid, 'Description', description);
      addRow(grid, 'Type', resourceType);
      addRow(grid, 'Privacy', privacy.map((e) => e.toString()).join(', '));
      addRow(grid, 'Cultural Responsiveness', culturalResponsiveness);
      if(resourceType == "In Person")
        {
          addRow(grid, 'Address', fullAddress);
        }
      if(resourceType == "Hotline" || resourceType == "In Person")
        {
          addRow(grid, 'Phone Number', phoneNumber);
        }

      addRow(grid, 'URL', urlStr);

      // set grid padding
      grid.style.cellPadding = PdfPaddings(left: 5, top: 5);

      // display the grid
      grid.draw(
          page: page,
          bounds: Rect.fromLTWH(0, 0,0, 0,)
      );
      // save the document
      List<int> pdfBytes = await document.save();

      html.AnchorElement(
          href:
          "data:application/pdf;base64, ${base64.encode(pdfBytes)}")
        ..setAttribute("download", name +"-resource.pdf")
        ..click();

      // dispose the document
      document.dispose();
    }
    // otherwise print error downloading
    catch (e) {
      print('Error: $e');
    }
  }

  // function to add rows to a grid
  void addRow(PdfGrid grid, String label, dynamic value) {
    PdfGridRow row = grid.rows.add();
    row.cells[0].value = label;
    row.cells[1].value = value.toString();
  }
}

