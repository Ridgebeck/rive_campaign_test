import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

const int totalLevels = 100;
int activeLevel = 5;
const double boxHeight = 200;

ScrollController scrollController = ScrollController(initialScrollOffset: currentScrollPosition());

double currentScrollPosition({int offset = 0}) {
  return max(0, (activeLevel + offset - 3) * boxHeight); //TODO: REPLACE # WITH SCREEN HEIGHT RATIO
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RiveCampaignTest(),
    );
  }
}

class RiveCampaignTest extends StatefulWidget {
  const RiveCampaignTest({super.key});

  @override
  State<RiveCampaignTest> createState() => _RiveCampaignTestState();
}

class _RiveCampaignTestState extends State<RiveCampaignTest> {
  /// Tracks if the animation is playing by whether controller is running.
  //bool get isPlaying => _controller?.isActive ?? false;

  List<RiveFile?> riveFilesDot = [];
  List<SMIInput<double>?> stateNumberInputsDot = [];
  List<SMITrigger?> clickedTriggers = [];

  List<RiveFile?> riveFilesLine = [];
  List<SMIInput<double>?> lengthInputs = [];
  List<SMIInput<double>?> stateNumberInputsLine = [];

  @override
  void initState() {
    super.initState();

    // load dot animation file from the bundle
    rootBundle.load('assets/dot.riv').then(
      (dotData) async {
        // load RiveFile from the binary data
        for (int i = 0; i < totalLevels; i++) {
          riveFilesDot.add(RiveFile.import(dotData));
        }
        // load line animation file from the bundle
        rootBundle.load('assets/line.riv').then((lineData) async {
          // load RiveFile from the binary data
          for (int i = 0; i < totalLevels; i++) {
            riveFilesLine.add(RiveFile.import(lineData));
          }
          // set state to update screen after loading
          setState(() {});
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return riveFilesDot.length != totalLevels
        ? const SizedBox() // TODO: REPLACE WITH LOADING
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () async {
                    print('pressed');
                    stateNumberInputsLine[activeLevel]!.value = 1;
                    // change active level to solved
                    stateNumberInputsDot[activeLevel]!.value = 2;
                    // wait 500ms (half of animation time)
                    await Future.delayed(const Duration(milliseconds: 500));
                    // change next level to active
                    stateNumberInputsDot[activeLevel + 1]!.value = 1;
                    scrollController
                        .animateTo(
                      currentScrollPosition(offset: 1),
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeInOut,
                    )
                        .then((value) {
                      // setState(() {
                      activeLevel += 1;
                      // });
                    });
                  },
                  child: const Text('WON')),
              const SizedBox(height: 50),
              Expanded(
                child: ListView.builder(
                    controller: scrollController,
                    itemCount: totalLevels,
                    reverse: true,
                    itemBuilder: (context, index) {
                      // get artboard for each rive file
                      final dotArtboard = riveFilesDot[index]!.mainArtboard;
                      final lineArtboard = riveFilesLine[index]!.mainArtboard;

                      // get state machine controller from artboard
                      var dotController =
                          StateMachineController.fromArtboard(dotArtboard, 'State Machine 1');
                      var lineController =
                          StateMachineController.fromArtboard(lineArtboard, 'State Machine 1');
                      if (dotController != null) {
                        dotArtboard.addController(dotController);
                        // get inputs from state machine controller
                        var stateNumberInputDot =
                            dotController.findInput<double>('stateNumber') as SMINumber;
                        var clickedTrigger = dotController.findSMI('clickedTrigger') as SMITrigger;
                        // save inputs to lists
                        stateNumberInputsDot.add(stateNumberInputDot);
                        clickedTriggers.add(clickedTrigger);

                        // set states of dots
                        if (index > activeLevel) {
                          stateNumberInputDot.value = 0;
                        } else if (index == activeLevel) {
                          stateNumberInputDot.value = 1;
                        } else {
                          stateNumberInputDot.value = 2;
                        }
                      }
                      if (lineController != null) {
                        lineArtboard.addController(lineController);
                        // get inputs from state machine controller
                        var lengthInput = lineController.findInput<double>('length') as SMINumber;
                        var stateNumberInputLine =
                            lineController.findInput<double>('stateNumber') as SMINumber;
                        // save inputs to lists
                        lengthInputs.add(lengthInput);
                        stateNumberInputsLine.add(stateNumberInputLine);

                        // set length
                        lengthInput.value = boxHeight;

                        // set states of lines
                        if (index >= activeLevel) {
                          stateNumberInputLine.value = 0;
                        } else {
                          stateNumberInputLine.value = 1;
                        }
                      }

                      return Center(
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              bottom: boxHeight / 2 - 25,
                              left: 0,
                              child: Rive(
                                useArtboardSize: true,
                                //fit: BoxFit.fitWidth,
                                artboard: lineArtboard,
                              ),
                            ),
                            Container(
                              height: boxHeight,
                              width: 100,
                              //color: Colors.green,
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {
                                    print('Dot $index touched...');
                                    clickedTriggers[index]!.fire();
                                  },
                                  child: Rive(
                                    artboard: dotArtboard,
                                  ),
                                ),
                              ),
                            ),
                            // Positioned(
                            //   bottom: boxHeight / 2 - 25,
                            //   left: 0,
                            //   child: Rive(
                            //     useArtboardSize: true,
                            //     //fit: BoxFit.fitWidth,
                            //     artboard: lineArtboard,
                            //   ),
                            // ),
                          ],
                        ),
                      );
                    }),
              ),
            ],
          );
  }
}
