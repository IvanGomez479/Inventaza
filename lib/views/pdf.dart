import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

import '../models/Pieza.dart';

class PDF extends StatefulWidget {
  late Pieza pieza;
  PDF({super.key, required this.pieza});

  @override
  State<PDF> createState() => _PDFState();
}

class _PDFState extends State<PDF> {
  late pw.Document pdf;
  late PdfImage imagen;
  late Uint8List archivoPdf;
  late List<Pieza> listaPiezasHijas = [];
  late List<pw.Widget> piezasHijasWidgets = [];
  bool isLoading = true;

  ///{@macro initState}
  @override
  void initState() {
    super.initState();
    initPDF();
  }

  ///Método que inicializará el PDF
  Future<void> initPDF() async {
    try {
      archivoPdf = await generarPDF();
      listaPiezasHijas = await getPiezasHijas(widget.pieza);
      piezasHijasWidgets = await crearPiezasHijasPDFPrueba(listaPiezasHijas);
    } catch (e) {
      print('Error en initPDF: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  ///{@macro getPiezasHijas}
  Future<List<Pieza>> getPiezasHijas(Pieza pieza) async {
    final String codPieza = "${pieza.codPropietario.toString()}${pieza.codPieza.toString()}";
    var url = Uri.parse("http://www.ies-azarquiel.es/paco/apiinventario/padre/$codPieza/pieza");
    final response = await http.get(url);

    List<Pieza> piezas = [];

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);

      final jsonData = jsonDecode(body);

      if (jsonData["piezashijas"] != null) {
        for (var item in jsonData["piezashijas"]) {
          piezas.add(Pieza(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
          title: const Text("PDF"),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    colors: <Color>[
                  Colors.lightBlueAccent,
                  Colors.cyanAccent
                ])
            ),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          actionsIconTheme: const IconThemeData.fallback(),

      ),
      //Botón flotante para compartir el PDF
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
        onPressed: () async => {
          // Compartimos el PDF a la aplicación que se desee
          await Printing.sharePdf(
              bytes: archivoPdf,
              filename:
                  'Pieza: ${widget.pieza.codPropietario.toString()}-${widget.pieza.codPieza.toString()}-${widget.pieza.codNIF.toString()}.pdf'),
        },
        child: const Icon(Icons.share),
      ),
      body: SafeArea(
        child: Visibility(
          visible: !isLoading,
          replacement: const Center(
            child: CircularProgressIndicator(),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 600,
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
          ), // show a loading indicator
        )
      )
    );
  }

  ///Método que, a través de recursividad, devolverá una lista de Widgets con toda la información de las piezas hijas de una pieza
  Future<List<pw.Widget>> crearPiezasHijasPDFPrueba(List<Pieza> listaPiezasHijas) async {

    for (Pieza pieza in listaPiezasHijas) {
      piezasHijasWidgets.add(
        pw.Row(children: [
          pw.Text(
            "PIEZA: ${pieza.codPropietario.toString()}-${pieza.codPieza.toString()}-${pieza.codNIF.toString()}",
            style: const pw.TextStyle(fontSize: 15.5),
          ),
        ]),
      );
      piezasHijasWidgets.add(
        pw.Row(children: [
          pw.Text(
            pieza.identificador.toString(),
            style: const pw.TextStyle(fontSize: 15.5),
          ),
        ]),
      );
      piezasHijasWidgets.add(
        pw.Row(children: [
          pw.Text(
            "Modelo: ${pieza.descModelo.toString()}",
            style: const pw.TextStyle(fontSize: 15.5),
          ),
        ]),
      );
      piezasHijasWidgets.add(
        pw.Row(children: [
          pw.Text(
            "Tipo: ${pieza.descTipo.toString()} - ${pieza.descSubTipo.toString()}",
            style: const pw.TextStyle(fontSize: 15.5),
          ),
        ]),
      );
      piezasHijasWidgets.add(
        pw.Row(children: [
          pw.Text(
            "Fabricante: ${pieza.nombreFabricante.toString()}",
            style: const pw.TextStyle(fontSize: 15.5),
          ),
        ]),
      );
      piezasHijasWidgets.add(
        pw.Row(children: [
          pw.SizedBox(height: 21.0)
        ]),
      );

      if (pieza.contenedor == "true") {
        List<Pieza> listaPiezasHijasDeHija = await getPiezasHijas(pieza);
        await crearPiezasHijasPDFPrueba(listaPiezasHijasDeHija);
      }
    }

    return piezasHijasWidgets;
  }


  ///Método que genera el PDF
  Future<Uint8List> generarPDF() async {
    pdf = pw.Document();

    final response = await http.get(Uri.parse(
        'http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${widget.pieza.codModelo.toString()}.jpg'));
    final bytes = response.bodyBytes;
    final image = pw.MemoryImage(bytes);

    listaPiezasHijas = await getPiezasHijas(widget.pieza);
    piezasHijasWidgets = await crearPiezasHijasPDFPrueba(listaPiezasHijas);

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
                  widget.pieza.descPropietario.toString(),
                  style: const pw.TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Text(
                  "Modelo: ${widget.pieza.descModelo.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                ),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                widget.pieza.identificador.toString() != ""
                    ? pw.Text(
                        "Contenedor: ${widget.pieza.identificador.toString()}",
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
                  "Tipo: ${widget.pieza.descTipo.toString()} - ${widget.pieza.descSubTipo.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                ),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Text(
                  "Fabricante: ${widget.pieza.nombreFabricante.toString()}",
                  style: const pw.TextStyle(fontSize: 15.0),
                ),
              ]),
            ],
          ),
        ],
      ),
    );

    if (widget.pieza.contenedor == "true" && piezasHijasWidgets.length < 700) {
      pdf.addPage(pw.MultiPage(
        footer: _buildFooter,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Column(children: [
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                "Contenido",
                style: pw.TextStyle(
                    fontSize: 30.0, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20.0),
            ...piezasHijasWidgets
          ]),
        ],
      ));
    }

    return pdf.save();
  }

  ///Cabecera del PDF (título)
  pw.Widget _buildHeader(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "PIEZA: ${widget.pieza.codPropietario.toString()}-${widget.pieza.codPieza.toString()}-${widget.pieza.codNIF.toString()}",
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

  ///Pie de página del PDF (número de página)
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
