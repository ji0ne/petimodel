import 'package:firstnote/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ble testing'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final BleController controller = Get.put(BleController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // 상단 절반: 시리얼 모니터
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.black,
              child: Obx(() => ListView(
                children: controller.receivedDataList.map((data) => Text(
                  data,
                  style: TextStyle(color: Colors.green),
                )).toList(),
              )),
            ),
          ),
          // 하단 절반: 블루투스 기기 리스트
          Expanded(
            flex: 1,
            child: GetBuilder<BleController>(
              builder: (controller) {
                return StreamBuilder<List<ScanResult>>(
                  stream: controller.scanResults,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data![index];
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              title: Text(data.device.name.isEmpty ? 'Unknown Device' : data.device.name),
                              subtitle: Text(data.device.id.id),
                              trailing: Text(data.rssi.toString()),
                              onTap: () => controller.connectToDevice(data.device),
                            ),
                          );
                        },
                      );
                    } else {
                      return Center(child: Text("No device found"));
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.scanDevices(),
        child: const Icon(Icons.search),
      ),
    );
  }
}