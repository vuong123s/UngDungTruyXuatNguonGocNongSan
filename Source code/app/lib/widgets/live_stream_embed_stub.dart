import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LiveStreamEmbed extends StatefulWidget {
  const LiveStreamEmbed({super.key, required this.url});

  final String url;

  @override
  State<LiveStreamEmbed> createState() => _LiveStreamEmbedState();
}

class _LiveStreamEmbedState extends State<LiveStreamEmbed> {
  WebViewController? _controller;
  int _loadingProgress = 0;
  String? _error;

  bool get _supportsWebView =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_supportsWebView) _initializeWebView();
  }

  void _initializeWebView() {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null || !uri.hasScheme) {
      _error = 'URL camera không hợp lệ.';
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame == false) return;
            setState(() => _error = 'Không tải được luồng: ${error.description}');
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsWebView) {
      return _UnsupportedStream(url: widget.url);
    }
    if (_error != null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    if (_controller == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller!),
        if (_loadingProgress < 100)
          LinearProgressIndicator(value: _loadingProgress / 100),
      ],
    );
  }
}

class _UnsupportedStream extends StatelessWidget {
  const _UnsupportedStream({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.live_tv_rounded, color: Colors.white, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Nền tảng này chưa hỗ trợ WebView. Hãy dùng link HLS, MP4 hoặc mở bản web.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          SelectableText(
            url,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
