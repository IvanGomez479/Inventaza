import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:pfc_inventaza/views/pdf.dart';

import '../models/Pieza.dart';
import '../models/PiezaView.dart';

class PiezaDetail extends StatefulWidget {
  static final navKey = GlobalKey<NavigatorState>();
  late PiezaView piezaView;

  PiezaDetail({required this.piezaView});

  @override
  _PiezaDetailState createState() => _PiezaDetailState();
}

class _PiezaDetailState extends State<PiezaDetail> {
  late List<PiezaView> listadoPiezas = [];
  List<PiezaView> listadoPiezasBuscador = [];
  final TextEditingController searchController = TextEditingController();
  late List<PiezaView> data = [];
  late String? textBuscador = "";
  ScrollController _scrollController = ScrollController();
  bool mostrarClearButton = false;

  @override
  void initState() {
    super.initState();
    getPiezasHijas(widget.piezaView).then((value) {
      setState(() {
        listadoPiezas.addAll(value);
        listadoPiezasBuscador = listadoPiezas;
      });
    });
    searchController.addListener(checkInput);
  }

  void actualizarPiezas(PiezaView piezaView) {
    setState(() {
      widget.piezaView = piezaView;
      listadoPiezas = listaPiezasActualizada(piezaView);
      searchController.text = "";
    });
  }

  Future<List<PiezaView>> getPiezasHijas(PiezaView? piezaView) async {
    final String codPieza =
        "${piezaView?.codPropietario.toString()}${piezaView?.codPieza.toString()}";
    var url = Uri.parse(
        "http://www.ies-azarquiel.es/paco/apiinventario/padre/$codPieza/pieza");
    final response = await http.get(url);

    List<PiezaView> piezas = [];

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);

      final jsonData = jsonDecode(body);

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
      return piezas;
    } else {
      throw Exception("Falló la conexión");
    }
  }

  Future<PiezaView> getPiezaView(PiezaView piezaView) async {
    final String codPieza = "${piezaView.codPropietario.toString()}${piezaView.codPieza.toString()}${piezaView.codNIF.toString()}";

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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void checkInput() {
    setState(() {
      mostrarClearButton = searchController.text.isNotEmpty;
    });
  }

  void limpiarBuscador() {
    setState(() {
      searchController.clear();
      mostrarClearButton = false;
    });
  }

  updateListPiezas(String text) {
    text = text.toLowerCase();
    late String codPieza;
    setState(() {
      // Guardamos en una variable el valor de la nueva lista dependiendo de lo que se haya escrito en el buscador
      listadoPiezasBuscador = listadoPiezas.where((piezaView) {
        codPieza = "${piezaView.codPropietario.toString()}-${piezaView.codPieza.toString()}-${piezaView.codNIF.toString()}";
        var codPiezaSearch = codPieza.toLowerCase();
        return codPiezaSearch.contains(text);
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
                  "PIEZA: ${widget.piezaView.codPropietario.toString()}-${widget.piezaView.codPieza.toString()}-${widget.piezaView.codNIF.toString()}"),
              centerTitle: true,
              collapseMode: CollapseMode.parallax,
              background: Image(
                image: NetworkImage(
                    "http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${widget.piezaView.codModelo.toString()}.jpg"),
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
                                    icon: const Icon(Icons.clear),
                                    onPressed: limpiarBuscador,
                                    )
                                    : null,
                        ),
                      ),
                    ),
                  Expanded(
                      child: FutureBuilder(
                          future: getPiezasHijas(widget.piezaView),
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
                              return const Text(
                                "Esta pieza está vacía",
                                style: TextStyle(
                                  fontSize: 20.0
                                ),
                              );
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
  List<Widget> listPiezas(List<PiezaView> data) {
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
                                        child: pieza.identificador.toString() != "null" && pieza.identificador.toString() != ""
                                        ? Text(
                                          pieza.identificador.toString(),
                                          style: const TextStyle(
                                            fontSize: 15,
                                          ))
                                        : const Text(
                                          "Información no disponible",
                                          style: TextStyle(
                                            fontSize: 14,
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
  List<PiezaView> listaPiezasActualizada(PiezaView piezaView) {
    getPiezasHijas(piezaView).then((value) {
      data.addAll(value);
    });

    return data;
  }

  void _scrollTo(int index) {
    _scrollController.animateTo(
      index * 56.0, // Cada elemento tiene una altura estimada de 56.0 píxeles
      duration: const Duration(milliseconds: 500),
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
          MaterialPageRoute(builder: (context) => PDF(piezaView: widget.piezaView)),
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
void showError(BuildContext context, PiezaView piezaView) {
  Widget yesButton = TextButton(
    child: const Text("Sí"),
    // Si se pulsa el botón, navegamos a la pantalla del PDF
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PDF(piezaView: piezaView)),
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
    content: const Text("Esta pieza no contiene a ninguna otra, ¿Te gustaría generar su PDF?"),
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
