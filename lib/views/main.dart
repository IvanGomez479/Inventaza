import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pfc_inventaza/views/pdf.dart';
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
  bool mostrarClearButton = false;

  ///Método que realiza una petición GET a la API para obtener un listado de todas las piezas
  Future<List<Pieza>> getPiezas() async {
    var url = Uri.parse("http://www.ies-azarquiel.es/paco/apiinventario/piezaview");
    final response = await http.get(url);

    List<Pieza> piezas = [];

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);

      final jsonData = jsonDecode(body);

      for (var item in jsonData["piezas"]) {
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
      return piezas;
    } else {
      throw Exception("Falló la conexión");
    }
  }

  ///{@template initState}
  ///Método que se ejecuta al iniciar la pantalla
  ///{@endtemplate}
  @override
  void initState() {
    super.initState();
    getPiezas().then((value) {
      setState(() {
        listadoPiezas.addAll(value);
        listadoPiezasBuscador = listadoPiezas;
      });
    });
    searchController.addListener(checkInput);
  }

  ///{@template dispose}
  ///Método que realizará una limpieza de los recursos utilizados por el controlador
  ///{@endtemplate}
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  ///{@template checkInput}
  ///Método que comprueba si la barra de búsqueda está vacía para poner o no el botón de limpiar
  ///{@endtemplate}
  void checkInput() {
    setState(() {
      mostrarClearButton = searchController.text.isNotEmpty;
    });
  }

  ///{@template limpiarBuscador}
  ///Método que limpia la barra de búsqueda
  ///{@endtemplate}
  void limpiarBuscador() {
    setState(() {
      searchController.clear();
      mostrarClearButton = false;
    });
  }

  ///{@template updateListPiezasBuscador}
  ///Método que actualiza la lista de piezas en función de lo que se escriba en la barra de búsqueda
  ///{@endtemplate}
  updateListPiezasBuscador(String text) {
    text = text.toLowerCase();
    late String codPieza;
    setState(() {
      // Guardamos en una variable el valor de la nueva lista dependiendo de lo que se haya escrito en el buscador
      listadoPiezasBuscador = listadoPiezas.where((pieza) {
        codPieza =
        "${pieza.codPropietario.toString()}-${pieza.codPieza.toString()}-${pieza.codNIF.toString()}";
        var codPiezaSearch = codPieza.toLowerCase();
        return codPiezaSearch.contains(text);
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
                    onChanged: updateListPiezasBuscador(searchController.text),
                    decoration: InputDecoration(
                      labelText: 'Buscar',
                      prefixIcon: const Icon(Icons.search),
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
                      future: getPiezas(),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          return ListView(
                            // Cargaremos la lista que dependa de lo que se haya escrito en el buscador
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

  ///{@template listPiezas}
  ///Método que generará la lista de Cards(Widgets) a partir de una lista de piezas
  ///{@endtemplate}
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
                      fit: BoxFit.cover),
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
                                    child: pieza.identificador.toString() != "null" && pieza.identificador.toString() != ""
                                        ? Text(pieza.identificador.toString(),
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
                                          Navigator.push(
                                            context!,
                                            MaterialPageRoute(builder: (context) => PiezaDetail(pieza: pieza)),
                                          )
                                        }
                                      else
                                        {showError(context!, pieza)}
                                    },
                                    style: const ButtonStyle(
                                      backgroundColor: MaterialStatePropertyAll(
                                          Colors.lightBlueAccent),
                                      elevation: MaterialStatePropertyAll(20.0),
                                      foregroundColor: MaterialStatePropertyAll(
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
                    ),
                  ],
                )
            ),
          )
        ],
      ));
    }
    return piezas;
  }
}

///{@template showError}
///Método que muestra una ventana (AlertDialog) avisando de que la pieza pulsada no tiene piezas hijas,
///dando la posibilidad de generar directamente su PDF
///{@endtemplate}
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
