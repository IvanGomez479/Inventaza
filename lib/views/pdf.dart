import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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
  late PiezaView? piezaView;

  @override
  void initState() {
    initPDF();
    getPieza().then((value) {
      setState(() {
        piezaView = value;
      });
    });
  }

  Future<void> initPDF() async {
    archivoPdf = await generarPDF();
  }

  //Método que devuelve un objeto PiezaView para poder pintar sus datos en el PDF
  Future<PiezaView> getPieza() async {
    final String codPieza = "${widget.pieza.codPropietario.toString()}${widget.pieza.codPieza.toString()}${widget.pieza.codNIF.toString()}";

    var url = Uri.parse(
        "http://www.ies-azarquiel.es/paco/apiinventario/pieza/$codPieza");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);

      final jsonData = jsonDecode(body);

      final piezaView = PiezaView(
        jsonData['pieza']['CodPropietarioPadre'],
        jsonData['pieza']['CodPiezaPadre'],
        jsonData['pieza']['CodPropietario'],
        jsonData['pieza']['CodPieza'],
        jsonData['pieza']['CodNIF'],
        jsonData['pieza']['CodModelo'],
        jsonData['pieza']['Identificador'],
        jsonData['pieza']['Prestable'],
        jsonData['pieza']['Contenedor'],
        jsonData['pieza']['AltaPieza'],
        jsonData['propietario']['DescPropietario'],
        jsonData['modelo']['DescModelo'],
        jsonData['tipo']['DescTipo'],
        jsonData['subtipo']['DescSubTipo'],
        jsonData['fabricante']['NombreFabricante'],
      );

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
      //Botón flotante para compartir el PDF
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
        onPressed: () async => {
          // Compartimos el PDF a la aplicación que se desee
          await Printing.sharePdf(
              bytes: archivoPdf,
              filename: 'Pieza-${widget.pieza.codPieza.toString()}.pdf'),
        },
        child: const Icon(Icons.share),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
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

  // Método que genera el PDF
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
              pw.Row(children: [
                pw.Image(
                  image,
                  width: 450,
                  height: 450,
                ),
              ]),
              pw.SizedBox(height: 20),
              pw.Row(children: [
                pw.Text(
                  piezaView!.descPropietario.toString(),
                  style: const pw.TextStyle(
                      fontSize: 20.0,
                  ),
                ),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Text(
                  "Modelo: ${piezaView?.descModelo.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                ),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Text(
                  "Contenedor: ${piezaView?.identificador.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                ),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Text(
                  "Tipo: ${piezaView?.descTipo.toString()} - ${piezaView?.descSubTipo.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                ),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Text(
                  "Fabricante: ${piezaView?.nombreFabricante.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // Cabecera del PDF (título)
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
              fontSize: 30,
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

  // Pie de página del PDF (número de página)
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
