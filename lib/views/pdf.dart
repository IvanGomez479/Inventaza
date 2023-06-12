import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

import '../models/Pieza.dart';
import '../models/PiezaView.dart';

class PDF extends StatefulWidget {
  late PiezaView piezaView;
  PDF({required this.piezaView});

  @override
  State<PDF> createState() => _PDFState();
}

class _PDFState extends State<PDF> {
  late pw.Document pdf;
  late PdfImage imagen;
  late Uint8List archivoPdf;
  //late PiezaView? piezaView;
  late List<PiezaView> listaPiezasHijas = [];
  late List<pw.Widget> piezasHijasWidgets = [];
  late List<pw.Widget> nuevosWidgets = [];
  int contador = 0;

  @override
  void initState() {
    super.initState();
    initPDF();
    // getPiezaView(widget.pieza).then((value) {
    //   setState(() {
    //     piezaView = value;
    //   });
    // });
  }

  // Future<void> initPDF() async {
  //   archivoPdf = await generarPDF();
  // }

  Future<void> initPDF() async {
    try {
      archivoPdf = await generarPDF();
      listaPiezasHijas = await getPiezasHijas(widget.piezaView);
      piezasHijasWidgets = await crearPiezasHijasPDFPrueba(listaPiezasHijas);
    } catch (e) {
      print('Error en initPDF: $e');
    }
  }

  Future<List<PiezaView>> getPiezasHijas(PiezaView piezaView) async {
    final String codPieza = "${piezaView.codPropietario.toString()}${piezaView.codPieza.toString()}";
    var url = Uri.parse("http://www.ies-azarquiel.es/paco/apiinventario/padre/$codPieza/pieza");
    final response = await http.get(url);

    List<PiezaView> piezas = [];

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);

      final jsonData = jsonDecode(body);

      if (jsonData["piezashijas"] != null) {
        for (var item in jsonData["piezashijas"]) {
          piezas.add(PiezaView(
            item['pieza']['CodPropietarioPadre'],
            item['pieza']['CodPiezaPadre'],
            item['pieza']['CodPropietario'],
            item['pieza']['CodPieza'],
            item['pieza']['CodNIF'],
            item['pieza']['CodModelo'],
            item['pieza']['Identificador'],
            item['pieza']['Prestable'],
            item['pieza']['Contenedor'],
            item['pieza']['AltaPieza'],
            item['propietario']['DescPropietario'],
            item['modelo']['DescModelo'],
            item['tipo']['DescTipo'],
            item['subtipo']['DescSubTipo'],
            item['fabricante']['NombreFabricante'],
          ));
        }
      }
      return piezas;

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
              filename: 'Pieza: ${widget.piezaView.codPropietario.toString()}-${widget.piezaView.codPieza.toString()}-${widget.piezaView.codNIF.toString()}.pdf'),
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

  // void crearPiezasHijasPDF(List<PiezaView> listaPiezasHijas) async {
  //
  //   for (PiezaView piezaView in listaPiezasHijas) {
  //     print('Código de la pieza: ${piezaView.codPieza}');
  //
  //     if (piezaView.contenedor == "true") {
  //       List<PiezaView> listaPiezasHijasDeHija = await getPiezasHijas(piezaView);
  //
  //       print('Subpiezas:');
  //       crearPiezasHijasPDF(listaPiezasHijasDeHija);
  //     }
  //   }
  // }

  Future<List<pw.Widget>> crearPiezasHijasPDFPrueba(List<PiezaView> listaPiezasHijas) async {

    for (PiezaView piezaView in listaPiezasHijas) {
      print('Pieza: ${piezaView.codPropietario}-${piezaView.codPieza}');
      contador++;
      piezasHijasWidgets.add(
        pw.Row(
            children: [
              pw.Text(
                "PIEZA: ${piezaView.codPropietario.toString()}-${piezaView.codPieza.toString()}-${piezaView.codNIF.toString()}",
                style: const pw.TextStyle(fontSize: 20.0),
              ),
            ]
        ),
      );

      if (piezaView.contenedor == "true") {
        List<PiezaView> listaPiezasHijasDeHija = await getPiezasHijas(piezaView);
        print('Subpiezas:');
        crearPiezasHijasPDFPrueba(listaPiezasHijasDeHija);
        contador++;


        //crearPiezasHijasPDFPrueba(listaPiezasHijasDeHija);
      }
    }

    print(contador);
    return piezasHijasWidgets;
  }

  // Método que genera el PDF
  Future<Uint8List> generarPDF() async {
    pdf = pw.Document();

    final response = await http.get(Uri.parse(
        'http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${widget.piezaView.codModelo.toString()}.jpg'));
    final bytes = response.bodyBytes;
    final image = pw.MemoryImage(bytes);

    //List<pw.Widget> piezasHijasWidgets = [];

    //this.piezasHijasWidgets = piezasHijasWidgets;

    //crearPiezasHijasPDF(listaPiezasHijas);

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
                  widget.piezaView.descPropietario.toString(),
                  style: const pw.TextStyle(
                      fontSize: 20.0,
                  ),
                ),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Text(
                  "Modelo: ${widget.piezaView.descModelo.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                ),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                widget.piezaView.identificador.toString() != ""
                ? pw.Text(
                  "Contenedor: ${widget.piezaView.identificador.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                  )
                : pw.Text(
                  "Contenedor: No disponible",
                  style: const pw.TextStyle(fontSize: 15.0),
                  ),

              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Text(
                  "Tipo: ${widget.piezaView.descTipo.toString()} - ${widget.piezaView.descSubTipo.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                ),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Text(
                  "Fabricante: ${widget.piezaView.nombreFabricante.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                ),
              ]),
            ],
          ),
        ],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        footer: _buildFooter,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Column(
            children: [
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  "Contenido",
                  style: pw.TextStyle(
                      fontSize: 30.0,
                      fontWeight: pw.FontWeight.bold
                  ),
                ),
              ),
              pw.SizedBox(height: 20.0),
              ...piezasHijasWidgets,
            ]
          ),
        ],
      )
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
            "PIEZA: ${widget.piezaView.codPropietario.toString()}-${widget.piezaView.codPiezaPadre.toString()}-${widget.piezaView.codNIF.toString()}",
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
