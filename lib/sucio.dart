import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/Pieza.dart';

class PiezaDetailView extends StatelessWidget {
  static final navKey = GlobalKey<NavigatorState>();
  late Pieza pieza;
  PiezaDetailView({required this.pieza, Key? key}) : super(key: key);

  late final Future<List<Pieza>> listadoPiezas;

  Future<List<Pieza>> getPiezas() async {
    late String codPieza;
    if (pieza.codPropietarioPadre == null) {
      codPieza = "00${pieza.codPiezaPadre.toString()}";
    } else {
      codPieza =
      "${pieza.codPropietarioPadre.toString()}${pieza.codPieza.toString()}";
    }
    var url = Uri.parse(
        "http://www.ies-azarquiel.es/paco/apiinventario/padre/$codPieza/pieza");
    final response = await http.get(url);

    List<Pieza> piezas = [];

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);

      final jsonData = jsonDecode(body);

      for (var item in jsonData["piezas"]) {
        piezas.add(Pieza(
          item["CodPropietarioPieza"],
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
    listadoPiezas = getPiezas();
    return Scaffold(
        appBar: AppBar(
            title: const Text("InventAza"),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Colors.lightBlueAccent, Colors.blue])),
            )),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          onPressed: () => {},
          child: const Icon(Icons.picture_as_pdf_rounded),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                // Add padding around the search bar
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                // Use a Material design search bar
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    // Add a clear button to the search bar
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => {},
                    ),
                    // Add a search icon or button to the search bar
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
              ),
            ),
            // Card(
            //     elevation: 30.0,
            //     child: Column(
            //       children: [
            //         Image.network(
            //             "http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${pieza.codModelo.toString()}.jpg",
            //         ),
            //               Container(
            //                 padding: const EdgeInsets.all(15.0),
            //                 child: Column(
            //                   mainAxisSize: MainAxisSize.max,
            //                   children: [
            //                     Row(
            //                       children: [
            //                         Text(
            //                           "PIEZA: ${pieza.codPropietario.toString()}-${pieza.codPiezaPadre.toString()}-${pieza.codNIF.toString()}",
            //                           textScaleFactor: 1.4,
            //                         ),
            //                       ],
            //                     ),
            //                     Row(
            //                       children: [
            //                         Text(
            //                           pieza.identificador.toString(),
            //                           style: const TextStyle(
            //                             fontSize: 15,
            //                           ),
            //                         ),
            //                       ],
            //                     ),
            //                     Row(
            //                       children: [
            //                         Text(
            //                           "Contenedor: ${pieza.codPropietario.toString()}-${pieza.codPropietarioPadre.toString()}",
            //                           textScaleFactor: 1.0,
            //                         ),
            //                       ],
            //                     ),
            //                   ],
            //                 ),
            //         )
            //       ],
            //     )
            // ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder(
                  future: listadoPiezas,
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      return ListView(
                        children: listPiezas(snapshot.data),
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

  List<Widget> listPiezas(List<Pieza>? data) {
    List<Widget> piezas = [];
    final context = PiezaDetailView.navKey.currentState?.context;

    for (var pieza in data!) {
      piezas.add(Flex(
        direction: Axis.horizontal,
        children: [
          Flexible(
            child: Card(
                margin: EdgeInsets.all(6.0),
                shadowColor: Colors.grey,
                elevation: 10.0,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: Image.network(
                          "http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${pieza.codModelo.toString()}.jpg"
                      ),
                    ),
                    Expanded(
                        flex: 5,
                        child: Wrap(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(15.0),
                                margin: const EdgeInsets.only(top: 0, right: 0, left: 0, bottom: 130.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "PIEZA: ${pieza.codPropietario.toString()}-${pieza.codPiezaPadre.toString()}-${pieza.codNIF.toString()}",
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
                                          "Contenedor: ${pieza.codPropietario.toString()}-${pieza.codPropietarioPadre.toString()}",
                                          textScaleFactor: 1.0,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: <Widget>[
                                        TextButton(
                                          onPressed: () => {
                                            if(pieza.contenedor == "true") {
                                              Navigator.push(
                                                context!,
                                                MaterialPageRoute(builder: (context) => PiezaDetailView(pieza: pieza)),
                                              )
                                            } else {
                                              showError(context!),
                                            }
                                          },
                                          style: const ButtonStyle(
                                            backgroundColor: MaterialStatePropertyAll(Colors.blueAccent),
                                            elevation: MaterialStatePropertyAll(20.0),
                                            foregroundColor: MaterialStatePropertyAll(Colors.white),
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
                            ]
                        )
                    ),
                  ],
                )),
          )
        ],
      ));
    }
    return piezas;
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
