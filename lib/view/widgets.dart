import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../services/data_service.dart';

class MyApp extends StatelessWidget {
  final DataService dataService = DataService();
  final TextEditingController searchController = TextEditingController();

  void updateSearchQuery(String query) {
    dataService.tableStateNotifier.value = {
      ...dataService.tableStateNotifier.value,
      'status': TableStatus.loading,
    };
    Future.delayed(Duration(milliseconds: 500), () {
      dataService.tableStateNotifier.value = {
        ...dataService.tableStateNotifier.value,
        'status': TableStatus.ready,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(actions: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: SizedBox(
                    width: 200,
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Pesquisar",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                      onChanged: (query) => updateSearchQuery(query),
                    ))),
            //arrowback
            IconButton(
                onPressed: () => dataService.undo(),
                icon: const Icon(Icons.arrow_back_outlined)),
            IconButton(
                onPressed: () => dataService.redo(),
                icon: const Icon(Icons.arrow_forward_outlined)),
          ]),
          body: ValueListenableBuilder(
              valueListenable: dataService.tableStateNotifier,
              builder: (_, value, __) {
                switch (value['status']) {
                  case TableStatus.idle:
                    return const Center(child: Text("Toque em algum botão"));

                  case TableStatus.loading:
                    return const Center(child: CircularProgressIndicator());

                  case TableStatus.ready:
                    return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SingleChildScrollView(
                              child: DataTableWidget(
                                  jsonObjects: value['dataObjects'],
                                  propertyNames: value['propertyNames'] ?? [],
                                  columnNames: value['columnNames'] ?? [],
                                  searchQuery: searchController.text,
                                  dataService: dataService)),
                        ]);

                  case TableStatus.error:
                    return const Text("Lascou");
                }

                return const Text("...");
              }),
          bottomNavigationBar: NewNavBar(
            itemSelectedCallback: dataService.load,
          ),
        ));
  }
}

class NewNavBar extends HookWidget {
  final itemSelectedCallback;

  NewNavBar({required this.itemSelectedCallback});

  @override
  Widget build(BuildContext context) {
    var state = useState(1);

    return BottomNavigationBar(
        onTap: (index) {
          state.value = index;

          itemSelectedCallback(index);
        },
        currentIndex: state.value,
        items: const [
          BottomNavigationBarItem(
            label: "Cafés",
            icon: Icon(Icons.coffee_outlined, color: Colors.black),
          ),
          BottomNavigationBarItem(
              label: "Cervejas",
              icon: Icon(Icons.local_drink, color: Colors.black)),
          BottomNavigationBarItem(
              label: "Nações",
              icon: Icon(Icons.flag_outlined, color: Colors.black)),
          BottomNavigationBarItem(
              label: "Sobremessas",
              icon: Icon(Icons.cake_outlined, color: Colors.black)),
        ]);
  }
}

class DataTableWidget extends StatelessWidget {
  final List jsonObjects;
  final List<String> columnNames;
  final List<String> propertyNames;
  final String searchQuery;
  final DataService dataService;

  DataTableWidget({
    this.jsonObjects = const [],
    this.columnNames = const [],
    this.propertyNames = const [],
    this.searchQuery = '',
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    List filteredObjects = jsonObjects;
    var sortCriteria = dataService.tableStateNotifier.value['sortCriteria'];
    var ascending = dataService.tableStateNotifier.value['ascending'];

    if (searchQuery.length >= 3) {
      filteredObjects = jsonObjects.where((obj) {
        for (var propName in propertyNames) {
          String propertyValue = obj[propName].toString().toLowerCase();
          String query = searchQuery.toLowerCase();

          if (propertyValue.contains(query)) {
            return true;
          }
        }

        return false;
      }).toList();
    }

    return columnNames.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Selecione uma opção no menu inferior",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ))
        : DataTable(
            columns: columnNames
                .asMap()
                .map(
                  (index, name) => MapEntry(
                    index,
                    DataColumn(
                      onSort: (columnIndex, ascending) => dataService
                          .sortCurrentState(propertyNames[columnIndex]),
                      label: Expanded(
                        child: InkWell(
                          onTap: () => dataService
                              .sortCurrentState(propertyNames[index]),
                          child: Row(
                            children: [
                              Text(
                                name,
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                              if (sortCriteria == propertyNames[index])
                                Icon(
                                  ascending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .values
                .toList(),
            rows: filteredObjects
                .map(
                  (obj) => DataRow(
                    cells: propertyNames
                        .map(
                          (propName) => DataCell(Text(obj[propName])),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          );
  }
}
