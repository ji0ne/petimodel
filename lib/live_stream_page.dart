import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LiveStreamPage extends StatefulWidget {
  final Function? onExit;

  const LiveStreamPage({
    this.onExit,
    Key? key,
  }) : super(key: key);

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> with WidgetsBindingObserver {
  late final WebViewController controller;
  bool isLoading = true;
  bool isStreamActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..clearCache()
      ..clearLocalStorage();

    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) => setState(() => isLoading = true),
        onPageFinished: (_) => setState(() {
          isLoading = false;
          isStreamActive = true;
        }),
        onNavigationRequest: (_) => NavigationDecision.navigate,
      ),
    );

    if (mounted) {
      await controller.loadRequest(
        Uri.parse('http://192.168.4.1:8080/'),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );
    }
  }

  Future<void> _cleanupStream() async {
    isStreamActive = false;
    await controller.clearCache();
    await controller.clearLocalStorage();
    await controller.loadRequest(Uri.parse('about:blank'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupStream();
    widget.onExit?.call();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 foreground로 돌아올 때
      _initializeStream();
    } else if (state == AppLifecycleState.paused) {
      // 앱이 background로 갈 때
      _cleanupStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _cleanupStream();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('라이브 스트리밍'),
          backgroundColor: Colors.deepOrange,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _cleanupStream();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _cleanupStream();
                await _initializeStream();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: controller),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepOrange,
                ),
              ),
          ],
        ),
      ),
    );
  }
}