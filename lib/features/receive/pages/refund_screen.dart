import 'package:aqua/features/shared/shared.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aqua/config/constants/urls.dart' as urls;

class RefundScreen extends StatefulWidget {
  static const routeName = '/refundScreen';
  const RefundScreen({super.key});

  @override
  State<RefundScreen> createState() => _RefundState();
}

class RefundArguments {
  final String refundJson;
  final String address;
  const RefundArguments(this.address, this.refundJson);
}

class _RefundState extends State<RefundScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {},
        onPageStarted: (String url) {},
        onPageFinished: (String url) async {
          final arguments =
              ModalRoute.of(context)?.settings.arguments as RefundArguments;
          await _controller.runJavaScript('''
            const jsonInput = document.getElementById("refundUpload");
            jsonInput.innerHTML = '${arguments.refundJson}'; 
            jsonInput.dispatchEvent(new Event("change"));

            const addressInput = document.getElementById("refundAddress");
            addressInput.value = "${arguments.address}"; 
            addressInput.dispatchEvent(new Event("input", {bubbles: true}));
            ''');
        },
        onWebResourceError: (WebResourceError error) {},
      ));
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as RefundArguments;
    _controller.loadRequest(
        Uri.parse("${urls.boltzWebAppUrl}refund?address=${arguments.address}"));

    return Scaffold(
      appBar: AquaAppBar(
        title: AppLocalizations.of(context)!.boltzRefund,
        showActionButton: false,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
