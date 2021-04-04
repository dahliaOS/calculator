/*
Copyright 2019 The dahliaOS Authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class _PiGameState extends State<PiGame> {
  // Statics
  TextSelection _currentSelection =
      TextSelection(baseOffset: 0, extentOffset: 0);
  final GlobalKey _textFieldKey = GlobalKey();
  final textFieldPadding = EdgeInsets.only(right: 8.0);
  static TextStyle textFieldTextStyle =
      TextStyle(fontSize: 80.0, fontWeight: FontWeight.w300);
  Color _numColor = Color.fromRGBO(48, 47, 63, .94);
  Color _opColor = Color.fromRGBO(22, 21, 29, .93);
  double? _fontSize = textFieldTextStyle.fontSize;
  // Controllers
  TextEditingController _controller = TextEditingController(text: '3.14_');
  final _pageController = PageController(initialPage: 0);
  // Pi Game variables
  int _strikes = 0;
  int _progress = 3;
  /// The first 100 digits of Pi, pre-buffered into the game.
  static const String _initbuffer = "3141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067";
  /// A multiple of 100. The end position of the buffer.
  int _bufferedTo = 100;
  /// The current buffer. It should hold up to 150 digits at a time; the first 50 digits are cut off after bypassing 50.
  String _buffer = _initbuffer;
  /// `false` if downloading the next 100 digits of Pi fails. Every press retries the download until it succeeds,
  /// setting this value to `true`.
  bool _bufferSuccess = true;
  bool get _isHalfway => (_progress % 50 == 0 && _progress % 100 != 0);
  String get _expectedDigit => _buffer[_progress-(_bufferedTo-_buffer.length)];

  void _onTextChanged() {
    final inputWidth =
        _textFieldKey.currentContext!.size!.width - textFieldPadding.horizontal;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: _controller.text,
        style: textFieldTextStyle,
      ),
    );
    textPainter.layout();

    var textWidth = textPainter.width;
    var fontSize = textFieldTextStyle.fontSize;

    while (textWidth > inputWidth && fontSize! > 40.0) {
      fontSize -= 0.5;
      textPainter.text = TextSpan(
        text: _controller.text,
        style: textFieldTextStyle.copyWith(fontSize: fontSize),
      );
      textPainter.layout();
      textWidth = textPainter.width;
    }

    setState(() {
      _fontSize = fontSize;
    });
  }

  void _append(String character) {
    if (_strikes == 3) {}
    else if (character == _expectedDigit) {
      setState(() {
        _controller.text = _controller.text.replaceFirst("_", character+"_");
        _progress++;
        // make it only show the last 9 digits input
        if (_controller.text.length > 10) _controller.text = _controller.text.substring(_controller.text.length-10);
      });
      if (_isHalfway || _bufferSuccess == false) http.get(Uri.parse("https://api.pi.delivery/v1/pi?start=$_bufferedTo&numberOfDigits=100")).then((response) {
        final nextHundo = jsonDecode(response.body)["content"];
        _buffer += nextHundo;
        _bufferedTo += 100;
        _buffer = _buffer.substring(49);
        if (mounted) setState(() {_bufferSuccess = true;});
      }).catchError((error) {
        if (mounted) setState(() {_bufferSuccess = false;});
      });
    }
    else setState(() {
      _strikes++;
    });
    _onTextChanged();
  }

  // void _clear() {
  //   setState(() {
  //     _controller.text = '';
  //     _buffer = _initbuffer;
  //     _bufferedTo = 100;
  //     _progress = 0;
  //     _strikes = 0;
  //   });
  //   _onTextChanged();
  // }

  Widget _buildButton(String label, [bool disabled = false]) {
    return Expanded(
      child: InkWell(
        onTap: (disabled || _strikes == 3) ? null : () => _append(label),
        child: Center(
            child: Text(
          label,
          style: TextStyle(
              fontSize:
                  (MediaQuery.of(context).orientation == Orientation.portrait)
                      ? 32.0
                      : 20.0, //24
              fontWeight: FontWeight.w300,
              color: (disabled || _strikes == 3) ? Colors.white60 : Colors.white),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0.0,
        actions: [
          if (!_bufferSuccess) Tooltip(message: "Cannot reach server", child: Icon(Icons.warning, color: Colors.amber)),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Text("SCORE: $_progress", style: Theme.of(context).textTheme.headline6),
          ),
          Icon(
            Icons.close,
            color: _strikes >= 1 ? Colors.red : Colors.white60,
          ),
          Icon(
            Icons.close,
            color: _strikes >= 2 ? Colors.red : Colors.white60,
          ),
          Icon(
            Icons.close,
            color: _strikes >= 3 ? Colors.red : Colors.white60,
          ),
          Container(width: 24)
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              key: _textFieldKey,
              controller: _controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: textFieldPadding,
              ),
              textAlign: TextAlign.right,
              style: textFieldTextStyle.copyWith(
                fontSize: _fontSize,
                color: _strikes == 3 ? Colors.red : Colors.green
              ),
              focusNode: AlwaysDisabledFocusNode(),
            )
          ),
          Expanded(
            flex: 5,
            child: Material(
              color: _opColor,
              child: PageView(
                controller: _pageController,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Expanded(
                              child: _strikes < 3 ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildButton('C', true),
                                  _buildButton('(', true),
                                  _buildButton(')', true),
                                ],
                              ) : Center(
                                child: Text(
                                  "YOU LOSE!",
                                  style: TextStyle(
                                      fontSize:
                                          (MediaQuery.of(context).orientation == Orientation.portrait)
                                              ? 32.0
                                              : 20.0, //24
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red,
                                ))
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Material(
                                color: _numColor,
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8)),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildButton('7'),
                                          _buildButton('8'),
                                          _buildButton('9'),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildButton('4'),
                                          _buildButton('5'),
                                          _buildButton('6'),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildButton('1'),
                                          _buildButton('2'),
                                          _buildButton('3'),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildButton('%', true),
                                          _buildButton('0'),
                                          _buildButton('.', true),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                          child: Column(
                        children: <Widget>[
                          _buildButton('÷', true),
                          _buildButton('×', true),
                          _buildButton('-', true),
                          _buildButton('+', true),
                          _buildButton('=', true),
                        ],
                      )),
                      InkWell(
                        child: Container(
                          color: Theme.of(context).accentColor,
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () => _pageController.animateToPage(
                          1,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease,
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: Theme.of(context).accentColor,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildButton('sin', true),
                              _buildButton('cos', true),
                              _buildButton('tan', true),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildButton('ln', true),
                              _buildButton('log', true),
                              _buildButton('√', true),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildButton('π', true),
                              _buildButton('e', true),
                              _buildButton('^', true),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildButton('INV', true),
                              _buildButton('PLAY', true),
                              _buildButton('!', true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PiGame extends StatefulWidget {
  @override
  _PiGameState createState() => _PiGameState();
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
