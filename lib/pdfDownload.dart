// pdfDownload.dart
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:web_app/view_resource/resource_detail.dart';

class PdfDownload {
  PdfDownload();
  // function that takes in a list of resources
  // that are currently being filtered for and
  // creates and downloads a pdf with the resource info
  Future<void>generateFilteredResourcesPdf(resources)
  async {
      // create a document
      PdfDocument document = PdfDocument();
      // add a page
      final PdfPage page = document.pages.add();
      PdfGrid grid = PdfGrid();
      // set number of columns
      grid.columns.add(count: 2);
      // add a header
      final PdfGridRow headerRow = grid.headers.add(1)[0];
      headerRow.cells[0].value = 'Resource Name';
      headerRow.cells[1].value = "Contact Info";
      // set header style
      headerRow.style.font = PdfStandardFont(PdfFontFamily.helvetica, 12,
          style: PdfFontStyle.bold);

      // loop the resource list
      for (final resource in resources)
      {
        if(resource['resourceType'] == "In Person")
          {
            // get the full address
            final String? fullAddress = formatResourceAddress(resource);

            // add full address to pdf
            addRow(grid, resource['name'], fullAddress);
          }
        else if(resource['resourceType'] == "Hotline")
          {
            // add phone number to pdf
            addRow(grid, resource['name'], resource['phoneNumber']);
          }
        else
          {
            // add link to pdf
            // TODO: shorten link
            addRow(grid, resource['name'], resource['location']);
          }
      }

      // set grid padding
      grid.style.cellPadding = PdfPaddings(left: 5, top: 5);

      // display the grid
      grid.draw(
          page: page,
          bounds: Rect.fromLTWH(0, 0, 0, 0,));
      // save the document
      final List<int> pdfBytes = await document.save();

      // dispose the document
      document.dispose();

      // download filtered list of resources pdf
      downloadPdf(pdfBytes, "Resources");
  }

  // function that takes in resource info and creates pdf
  Future<List<int>> generateResourcePdf(
    String name,
    String description,
    String resourceType,
    List<dynamic> privacy,
    List<dynamic> healthFocus,
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
      addRow(grid, 'Health Focus', healthFocus.map((e) => e.toString()).join(', '));
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

  // function to download the resource pdf
  Future<void> downloadPdf(pdfBytes, fileName) async {

    html.AnchorElement(
        href: "data:application/pdf;base64, ${base64.encode(pdfBytes)}")
      ..setAttribute("download", fileName + ".pdf")
      ..click();
  }

  // function to share resource
  Future<void> shareResourceLink (String name, Uri? urlStr) async {
    // share resource link
    await Share.share( "Check out this resource here: ${urlStr}",
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
