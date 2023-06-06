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
  late List<Pieza> data = [];
  late String? textBuscador = "";
  ScrollController _scrollController = ScrollController();
  bool mostrarClearButton = false;

  @override
  void initState() {
    super.initState();
    getPiezasHijas(widget.pieza).then((value) {
      setState(() {
        listadoPiezas.addAll(value);
        listadoPiezasBuscador = listadoPiezas;
      });
    });
    searchController.addListener(_checkInput);
  }

  void actualizarPiezas(Pieza pieza) {
    setState(() {
      widget.pieza = pieza;
      listadoPiezas = listaPiezasActualizada(widget.pieza);
      searchController.text = "";
    });
  }

  Future<List<Pieza>> getPiezasHijas(Pieza pieza) async {
    final String codPieza =
        "${pieza.codPropietario.toString()}${pieza.codPieza.toString()}";
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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _checkInput() {
    setState(() {
      mostrarClearButton = searchController.text.isNotEmpty;
    });
  }

  void _clearSearch() {
    setState(() {
      searchController.clear();
      mostrarClearButton = false;
    });
  }

  updateListPiezas(String text) {
    text = text.toLowerCase();
    setState(() {
      // Guardamos en una variable el valor de la nueva lista dependiendo de lo que se haya escrito en el buscador
      listadoPiezasBuscador = listadoPiezas.where((pieza) {
        var codPiezaSearch = pieza.codPieza.toString().toLowerCase();
        return codPiezaSearch.startsWith(text);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Botón flotante del generador de PDFs
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          onPressed: () => {showDialogPDF(context)},
          child: const Icon(Icons.picture_as_pdf_rounded),
        ),
        body: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            scrolledUnderElevation: 10.0,
            backgroundColor: Colors.lightBlueAccent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                  "PIEZA: ${widget.pieza.codPropietario.toString()}-${widget.pieza.codPieza.toString()}-${widget.pieza.codNIF.toString()}"),
              centerTitle: true,
              collapseMode: CollapseMode.parallax,
              background: Image(
                image: NetworkImage(
                    "http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${widget.pieza.codModelo.toString()}.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverFillRemaining(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      // Cada vez que se escriba una letra en el buscador, se ejecutará este código
                      onChanged: updateListPiezas(searchController.text),
                      decoration: InputDecoration(
                        labelText: 'Buscar',
                        prefixIcon:const Icon(Icons.search),
                        suffixIcon: mostrarClearButton
                                    ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: _clearSearch,
                                    )
                                    : null,
                        ),
                      ),
                    ),
                  Expanded(
                      child: FutureBuilder(
                          future: getPiezasHijas(widget.pieza),
                          builder: (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.hasData) {
                              return ListView(
                                controller: _scrollController,
                                children: searchController.text == ""
                                    ? listPiezas(snapshot.data) //Lista de piezas de la Pieza pulsada
                                    : listPiezas(listadoPiezasBuscador), // Lista que depende del buscador
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
                          }))
                ],
              )),
        ]));
  }

  //Método que genera la lista de Widgets a partir de una lista de objetos Pieza
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
                                    Flexible(
                                        child: Text(
                                          "PIEZA: ${pieza.codPropietario.toString()}-${pieza.codPieza.toString()}-${pieza.codNIF.toString()}",
                                          style: const TextStyle(
                                            fontSize: 18.2,
                                          ),
                                        ),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                        child: Text(
                                          pieza.identificador.toString(),
                                          style: const TextStyle(
                                            fontSize: 15,
                                          ),
                                        ),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                        child: Text(
                                          "Contenedor: ${pieza.codPropietarioPadre.toString()}-${pieza.codPiezaPadre.toString()}",
                                          textScaleFactor: 1.0,
                                        ),
                                    )
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    TextButton(
                                      onPressed: () => {
                                        if (pieza.contenedor == "true") {
                                          actualizarPiezas(pieza),
                                          _scrollTo(0)
                                        }
                                        else
                                          {
                                            showError(context, pieza),
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

  //Método que devuelve una lista de piezas a partir de un objeto Pieza
  List<Pieza> listaPiezasActualizada(Pieza pieza) {
    getPiezasHijas(pieza).then((value) {
      data.addAll(value);
    });

    return data;
  }

  void _scrollTo(int index) {
    _scrollController.animateTo(
      index * 56.0, // Cada elemento tiene una altura estimada de 56.0 píxeles
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  // Método que muestra una ventana que pregunta si se desea continuar a la siguiente pantalla
  void showDialogPDF(BuildContext context) {
    // Creamos los botones
    Widget yesButton = TextButton(
      child: const Text("Sí"),
      // Si se pulsa el botón, navegamos a la pantalla del PDF
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PDF(pieza: widget.pieza)),
        );
      },
    );
    Widget noButton = TextButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("PDF Generator"),
      content: const Text("¿Quieres generar un PDF de esta Pieza?"),
      actions: [
        yesButton,
        noButton
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

// Método que muestra una ventana (AlertDialog) avisando de que la pieza pulsada no tiene piezas hijas
void showError(BuildContext context, Pieza pieza) {
  Widget yesButton = TextButton(
    child: const Text("Sí"),
    // Si se pulsa el botón, navegamos a la pantalla del PDF
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PDF(pieza: pieza)),
      );
    },
  );
  Widget noButton = TextButton(
    child: const Text("No"),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: const Text("Error"),
    content: const Text("Esta pieza no contiene a otras, ¿Te gustaría generar su PDF?"),
    actions: [
      yesButton,
      noButton
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
