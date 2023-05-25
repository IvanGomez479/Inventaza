import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

import '../models/Pieza.dart';
import '../models/PiezaView.dart';

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
  late Future<PiezaView> piezaView;

  @override
  void initState() {
    initPDF();
    piezaView = getPieza();
  }

  Future<void> initPDF() async {
    archivoPdf = await generarPDF();
  }

  Future<PiezaView> getPieza() async {
    late String codPieza;

    if (widget.pieza.codPropietarioPadre == null) {
      codPieza = "00${widget.pieza.codPiezaPadre.toString()}${widget.pieza.codNIF.toString()}";
    } else {
      codPieza = "${widget.pieza.codPropietarioPadre.toString()}${widget.pieza.codPieza.toString()}${widget.pieza.codNIF.toString()}";
    }
    var url = Uri.parse(
        "http://www.ies-azarquiel.es/paco/apiinventario/pieza/$codPieza");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);

      final jsonData = jsonDecode(body);

      final piezaView = PiezaView.fromJson(jsonData);

      return piezaView;
    } else {
      throw Exception("Falló la conexión");
    }
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
        onPressed: () async => {
          await Printing.sharePdf(
          bytes: archivoPdf, filename: 'Pieza-${widget.pieza.codPieza.toString()}.pdf'),
      },
        child: const Icon(Icons.share),
      ),
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

    final response = await http.get(Uri.parse(
        'http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${widget.pieza.codModelo.toString()}.jpg'));
    final bytes = response.bodyBytes;
    final image = pw.MemoryImage(bytes);

    pdf.addPage(
      pw.MultiPage(
        header: _buildHeader,
        footer: _buildFooter,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Column(
            children: [
              pw.Row(
                children: [
                  pw.Image(
                    image,
                    width: 450,
                    height: 450,
                  ),
                ]
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                children: [
                  pw.Text(
                      widget.pieza.identificador.toString(),
                      style: const pw.TextStyle(fontSize: 20.0),
                  ),
                ]
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                  children: [
                    pw.Text(
                      "Contenedor: ${widget.pieza.codPropietarioPadre.toString()==null ? "00":"00"}-${widget.pieza.codPieza}",
                      style: const pw.TextStyle(fontSize: 20.0),
                    ),
                  ]
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                  children: [
                    pw.Text(
                      "Modelo: ${""}-${widget.pieza.codPieza}",
                      style: const pw.TextStyle(fontSize: 20.0),
                    ),
                  ]
              ),
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
            color: PdfColors.grey,
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
              fontSize: 10,
              color: PdfColors.grey,
            ),
            textAlign: pw.TextAlign.right,
          ),
          pw.SizedBox(
            height: 4,
          ),
          pw.Container(
            height: 1,
            color: PdfColors.grey,
          ),
        ],
      ),
    );
  }
}
