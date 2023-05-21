import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

import '../models/Pieza.dart';

class PDF extends StatefulWidget {
  late Pieza pieza;
  PDF({required this.pieza});

  @override
  State<PDF> createState() => _PDFState();
}

class _PDFState extends State<PDF> {
  late pw.Document pdf;
  late PdfImage imagen;
  late Uint8List archivoPdf;

  @override
  void initState() {
    initPDF();
  }

  Future<void> initPDF() async {
    archivoPdf = await generarPDF();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text("PDF"),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    colors: <Color>[
                  Colors.lightBlueAccent,
                  Colors.cyanAccent
                ])),
          )),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 540,
              width: double.maxFinite,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                child: PdfPreview(
                  build: (format) => archivoPdf,
                  useActions: false,
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Future<Uint8List> generarPDF() async {
    pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: _buildHeader,
        footer: _buildFooter,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Column(
            children: [pw.Row(
              children: [

              ]
            )
          ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "PIEZA: ${widget.pieza.codPropietario.toString()}-${widget.pieza.codPiezaPadre.toString()}-${widget.pieza.codNIF.toString()}",
            style: const pw.TextStyle(
              fontSize: 35,
              decorationStyle: pw.TextDecorationStyle.solid,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(
            height: 4,
          ),
          pw.Container(
            height: 1,
            color: PdfColors.green,
          ),
          pw.SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 20,
              color: PdfColors.grey,
            ),
            textAlign: pw.TextAlign.right,
          ),
          pw.SizedBox(
            height: 4,
          ),
          pw.Container(
            height: 1,
            color: PdfColors.green,
          ),
        ],
      ),
    );
  }
}
