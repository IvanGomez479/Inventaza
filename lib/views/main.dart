import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pfc_inventaza/views/piezaDetail.dart';

import '../models/Pieza.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static final navKey = GlobalKey<NavigatorState>();
  const MyApp({super.key, navKey});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late List<Pieza> listadoPiezas = [];
  List<Pieza> listadoPiezasBuscador = [];
  final TextEditingController searchController = TextEditingController();
  bool _showClearButton = false;

  Future<List<Pieza>> getPiezas() async {
    var url = Uri.parse("http://www.ies-azarquiel.es/paco/apiinventario/pieza");
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
  void initState() {
    getPiezas().then((value) {
      setState(() {
        listadoPiezas.addAll(value);
        listadoPiezasBuscador = listadoPiezas;
      });
    });
    searchController.addListener(_checkInput);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _checkInput() {
    setState(() {
      _showClearButton = searchController.text.isNotEmpty;
    });
  }

  void _clearSearch() {
    setState(() {
      searchController.clear();
      _showClearButton = false;
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
    return MaterialApp(
        navigatorKey: MyApp.navKey,
        title: "Material App",
        theme: ThemeData(scaffoldBackgroundColor: const Color(0xffc7e8fc)),
        home: Scaffold(
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
            body: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    // Cada vez que se escriba una letra en el buscador, se ejecutará este código
                    onChanged: updateListPiezas(searchController.text),
                    decoration: InputDecoration(
                      labelText: 'Buscar',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _showClearButton
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
                      future: getPiezas(),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          return ListView(
                            // Dependiendo de si se ha escrito algo en el buscador, cargaremos una lista u otra
                            children: listPiezas(listadoPiezasBuscador),
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
            )));
  }

  //método que generará la lista de Cards(Widgets) a partir de una lista de piezas
  List<Widget> listPiezas(List<Pieza> data) {
    List<Widget> piezas = [];
    final context = MyApp.navKey.currentState?.overlay?.context;

    for (var pieza in data) {
      piezas.add(Flex(
        direction: Axis.horizontal,
        children: [
          Flexible(
            child: Card(
                margin: const EdgeInsets.all(10.0),
                shadowColor: Colors.grey,
                elevation: 10.0,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: Image.network(
                        "http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${pieza.codModelo.toString()}.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                        flex: 5,
                        child: Container(
                            padding: const EdgeInsets.all(15.0),
                            margin: const EdgeInsets.only(
                               top: 0, right: 0, left: 0, bottom: 120.0),
                            alignment: AlignmentDirectional.topEnd,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "PIEZA: ${pieza.codPropietario.toString()}-${pieza.codPieza.toString()}-${pieza.codNIF.toString()}",
                                        style: const TextStyle(
                                          fontSize: 18.0,
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
                                        if (pieza.contenedor == "true")
                                          {
                                            Navigator.push(
                                              context!,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PiezaDetail(
                                                          pieza: pieza)),
                                            )
                                          }
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
                          )),
                  ],
                )),
          )
        ],
      ));
    }
    return piezas;
  }
}

// Método que muestra una ventana (AlertDialog) avisando de que la pieza pulsada no tiene piezas hijas
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
