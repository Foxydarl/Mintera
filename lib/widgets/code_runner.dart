import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class CodeRunner extends StatefulWidget {
  final String template;
  const CodeRunner({super.key, required this.template});
  @override
  State<CodeRunner> createState() => _CodeRunnerState();
}

class _CodeRunnerState extends State<CodeRunner> {
  late TextEditingController code;
  String output = '';
  bool running = false;

  @override
  void initState() {
    super.initState();
    code = TextEditingController(text: widget.template);
  }

  Future<void> run() async {
    setState(() { running = true; output = ''; });
    try {
      if (!kIsWeb) {
        setState(() { output = 'Исполнение кода доступно только в веб-сборке.'; });
      } else {
        final res = js.context.callMethod('eval', [code.text]);
        setState(() { output = '$res'; });
      }
    } catch (e) {
      setState(() { output = 'Ошибка: $e'; });
    } finally {
      setState(() { running = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: code, maxLines: 8, decoration: const InputDecoration(labelText: 'Код (JavaScript)')),
      const SizedBox(height: 8),
      Row(children: [
        FilledButton(onPressed: running? null : run, child: Text(running? 'Выполняется...' : 'Запустить')),
      ]),
      const SizedBox(height: 8),
      Text('Вывод:'),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
        child: Text(output.isEmpty ? '(нет вывода)' : output),
      )
    ]);
  }
}
