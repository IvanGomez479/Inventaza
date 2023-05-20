import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../models/Pieza.dart';

class PDF extends StatefulWidget {
  static const String id = 'pdf_screen';
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
    //archivoPdf = await generarPdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("PDF"),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 400,
                  width: double.maxFinite,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 25,
                    ),
                    child: PdfPreview(
                      build: (format) => archivoPdf,
                      useActions: false,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          //archivoPdf = await generarPDF();
                          setState(() {
                            //archivoPdf = archivoPdf
                          });
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          )
      ),
    );
  }
}

