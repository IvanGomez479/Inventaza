import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pfc_inventaza/views/pdf.dart';

import '../models/Pieza.dart';

class PiezaDetail extends StatefulWidget {
  static final navKey = GlobalKey<NavigatorState>();
  late Pieza pieza;
  late List<Pieza> piezas;

  PiezaDetail({required this.pieza});

  @override
  _PiezaDetailState createState() => _PiezaDetailState();
}

class _PiezaDetailState extends State<PiezaDetail> {
  late List<Pieza> listadoPiezas = [];
  List<Pieza> listadoPiezasBuscador = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getPiezas().then((value) {
      setState(() {
        listadoPiezas.addAll(value);
        listadoPiezasBuscador = listadoPiezas;
      });
    });
  }

  void actualizarPiezas(Pieza pieza) {
    setState(() {
      widget.pieza = pieza;
      actualizarListPiezasByPieza(widget.pieza);
    });
  }

  Future<List<Pieza>> getPiezas() async {
    final String codPieza = "${widget.pieza.codPropietarioPadre.toString()}${widget.pieza.codPiezaPadre.toString()}";
    var url = Uri.parse(
        "http://www.ies-azarquiel.es/paco/apiinventario/padre/$codPieza/pieza");
    final response = await http.get(url);

    List<Pieza> piezas = [];

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);

      final jsonData = jsonDecode(body);

      for (var item in jsonData["piezas"]) {
        piezas.add(Pieza(
          item["CodPropietarioPadre"],
          item["CodPiezaPadre"],
          item["CodPropietario"],
          item["CodPieza"],
          item["CodNIF"],
          item["CodModelo"],
          item["Identificador"],
          item["Prestable"],
          item["Contenedor"],
          item["AltaPieza"],
        ));
      }
      return piezas;
    } else {
      throw Exception("Falló la conexión");
    }
  }

  Future<List<Pieza>> getPiezasHijas(Pieza pieza) async {
    final String codPieza = "${widget.pieza.codPropietarioPadre.toString()}${widget.pieza.codPiezaPadre.toString()}";
    var url = Uri.parse(
        "http://www.ies-azarquiel.es/paco/apiinventario/padre/$codPieza/pieza");
    final response = await http.get(url);

    List<Pieza> piezas = [];

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);

      final jsonData = jsonDecode(body);

      for (var item in jsonData["piezas"]) {
        piezas.add(Pieza(
          item["CodPropietarioPadre"],
          item["CodPiezaPadre"],
          item["CodPropietario"],
          item["CodPieza"],
          item["CodNIF"],
          item["CodModelo"],
          item["Identificador"],
          item["Prestable"],
          item["Contenedor"],
          item["AltaPieza"],
        ));
      }
      return piezas;
    } else {
      throw Exception("Falló la conexión");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text("InventAza"),
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
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          onPressed: () => {showDialogPDF(context)},
          child: const Icon(Icons.picture_as_pdf_rounded),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (text) {
                  text = text.toLowerCase();
                  setState(() {
                    listadoPiezasBuscador = listadoPiezas.where((pieza) {
                      var noteTitle = pieza.codPieza.toString().toLowerCase();
                      return noteTitle.startsWith(text);
                    }).toList();
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Buscar',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Card(
                elevation: 30.0,
                child: Column(
                  children: [
                    Image.network(
                      "http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${widget.pieza.codModelo.toString()}.jpg",
                      height: 100,
                    ),
                    Container(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            children: [
                              Text(
                                "PIEZA: ${widget.pieza.codPropietario.toString()}-${widget.pieza.codPieza.toString()}-${widget.pieza.codNIF.toString()}",
                                textScaleFactor: 1.4,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                widget.pieza.identificador.toString(),
                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Contenedor: ${widget.pieza.codPropietario.toString()}-${widget.pieza.codPropietarioPadre.toString()}",
                                textScaleFactor: 1.0,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                )),
            Expanded(
              child: FutureBuilder(
                  future: getPiezasHijas(widget.pieza),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      return ListView(
                            children: listadoPiezas.length > 100
                                ? actualizarListPiezasByPieza(widget.pieza)
                                : listPiezas(listadoPiezasBuscador),
                      );
                    } else if (snapshot.hasError) {
                      if (kDebugMode) {
                        print(snapshot.error);
                      }
                      return const Text("Error");
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }),
            ),
          ],
        ));
  }

  List<Widget> listPiezas(List<Pieza> data) {
    List<Widget> piezas = [];

    for (var pieza in data) {
      piezas.add(Flex(
        direction: Axis.horizontal,
        children: [
          Flexible(
            child: Card(
                margin: const EdgeInsets.all(6.0),
                shadowColor: Colors.grey,
                elevation: 10.0,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: Image.network(
                          "http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${pieza.codModelo.toString()}.jpg"),
                    ),
                    Expanded(
                        flex: 5,
                        child: Wrap(children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(15.0),
                            margin: const EdgeInsets.only(
                                top: 0, right: 0, left: 0, bottom: 130.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "PIEZA: ${pieza.codPropietario.toString()}-${pieza.codPieza.toString()}-${pieza.codNIF.toString()}",
                                      style: const TextStyle(
                                        fontSize: 18.2,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      pieza.identificador.toString(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "Contenedor: ${pieza.codPropietarioPadre.toString()}-${pieza.codPiezaPadre.toString()}",
                                      textScaleFactor: 1.0,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    TextButton(
                                      onPressed: () => {
                                        if (pieza.contenedor == "true")
                                          {actualizarPiezas(pieza)}
                                        else
                                          {
                                            showError(context),
                                          }
                                      },
                                      style: const ButtonStyle(
                                        backgroundColor:
                                            MaterialStatePropertyAll(
                                                Colors.lightBlueAccent),
                                        elevation:
                                            MaterialStatePropertyAll(20.0),
                                        foregroundColor:
                                            MaterialStatePropertyAll(
                                                Colors.white),
                                      ),
                                      child: const Text(
                                        "Detail",
                                        style: TextStyle(
                                          decorationColor: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ])),
                  ],
                )),
          )
        ],
      ));
    }
    return piezas;
  }



  List<Widget> actualizarListPiezasByPieza(Pieza pieza) {
    pieza = widget.pieza;
    List<Widget> piezas = [];
    List<Pieza> data = [];

    getPiezasHijas(pieza).then((value) {
        data.addAll(value);
    });
    final context = PiezaDetail.navKey.currentState?.context;

    for (var pieza in data) {
      piezas.add(Flex(
        direction: Axis.horizontal,
        children: [
          Flexible(
            child: Card(
                margin: const EdgeInsets.all(6.0),
                shadowColor: Colors.grey,
                elevation: 10.0,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: Image.network(
                          "http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${pieza.codModelo.toString()}.jpg"),
                    ),
                    Expanded(
                        flex: 5,
                        child: Wrap(children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(15.0),
                            margin: const EdgeInsets.only(
                                top: 0, right: 0, left: 0, bottom: 130.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "PIEZA: ${pieza.codPropietario.toString()}-${pieza.codPieza.toString()}-${pieza.codNIF.toString()}",
                                      style: const TextStyle(
                                        fontSize: 18.2,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      pieza.identificador.toString(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "Contenedor: ${pieza.codPropietarioPadre.toString()}-${pieza.codPiezaPadre.toString()}",
                                      textScaleFactor: 1.0,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    TextButton(
                                      onPressed: () => {
                                        if (pieza.contenedor == "true")
                                          {actualizarPiezas(pieza)}
                                        else
                                          {
                                            showError(context!),
                                          }
                                      },
                                      style: const ButtonStyle(
                                        backgroundColor:
                                        MaterialStatePropertyAll(
                                            Colors.lightBlueAccent),
                                        elevation:
                                        MaterialStatePropertyAll(20.0),
                                        foregroundColor:
                                        MaterialStatePropertyAll(
                                            Colors.white),
                                      ),
                                      child: const Text(
                                        "Detail",
                                        style: TextStyle(
                                          decorationColor: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ])),
                  ],
                )),
          )
        ],
      ));
    }
    return piezas;
  }

  void showDialogPDF(BuildContext context) {
    // Creamos los botones
    Widget cancelButton = TextButton(
      child: const Text("Cancelar"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Continuar"),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PDF(pieza: widget.pieza)),
        );
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("PDF Generator"),
      content: const Text("¿Quieres generar un PDF de esta Pieza?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

void showError(BuildContext context) {
  Widget okButton = TextButton(
    child: const Text("OK"),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: const Text("Error"),
    content: const Text("Esta pieza no contiene a otras"),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

Future<void> generatePDF(Pieza pieza) async {
  final pdf = pw.Document();

  // Contenido del PDF
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Text(
              "${pieza.codPropietario.toString()}${pieza.codPieza.toString()}",
              style: const pw.TextStyle(fontSize: 40)),
        );
      },
    ),
  );

  // Guardar el archivo PDF
  final output = File('Downloads/archivo.pdf');
  await output.writeAsBytes(await pdf.save());
}
