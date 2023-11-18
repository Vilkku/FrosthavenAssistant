//portrait + name
//ability card
//stat sheet
//monster boxes
import 'package:flutter/material.dart';

import 'package:frosthaven_assistant/Layout/monster_ability_card.dart';
import 'package:frosthaven_assistant/Layout/monster_box.dart';
import 'package:frosthaven_assistant/Resource/commands/next_turn_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';

import '../Resource/color_matrices.dart';
import '../Resource/state/monster.dart';
import '../Resource/state/monster_instance.dart';
import '../services/service_locator.dart';
import 'monster_stat_card.dart';

class MonsterWidget extends StatefulWidget {
  final Monster data;

  final updateList = ValueNotifier<int>(0);

  MonsterWidget({Key? key, required this.data}) : super(key: key);

  @override
  MonsterWidgetState createState() => MonsterWidgetState();
}

class MonsterWidgetState extends State<MonsterWidget> {
  late List<MonsterInstance> lastList = [];

  @override
  void initState() {
    super.initState();
    lastList = widget.data.monsterInstances.value;
  }

  static const double SCALE_FACTOR = 0.8;

  Widget buildMonsterBoxGrid(double scale) {
    String displayStartAnimation = "";

    if (lastList.length < widget.data.monsterInstances.value.length) {
      //find which is new

      for (var item in widget.data.monsterInstances.value) {
        bool found = false;
        for (var oldItem in lastList) {
          if (item.standeeNr == oldItem.standeeNr) {
            found = true;
            break;
          }
        }
        if (!found) {
          displayStartAnimation = item.getId();
          break;
        }
      }
    }

    final generatedChildren = List<Widget>.generate(
        widget.data.monsterInstances.value.length,
        (index) => AnimatedSize(
              //not really needed now
              //TODO: try change to AnimatedContainer, and make sure to update the width on death (same time as death animation)
              key: Key(widget.data.monsterInstances.value[index].standeeNr
                  .toString()),
              duration: const Duration(milliseconds: 300),
              child: MonsterBox(
                  key: Key(widget.data.monsterInstances.value[index].standeeNr
                      .toString()),
                  figureId: widget.data.monsterInstances.value[index].name +
                      widget.data.monsterInstances.value[index].gfx +
                      widget.data.monsterInstances.value[index].standeeNr
                          .toString(),
                  ownerId: widget.data.id,
                  displayStartAnimation: displayStartAnimation,
                  blockInput: false,
                  scale: scale),
            ));
    lastList = widget.data.monsterInstances.value;
    return Wrap(
      runSpacing: 2.0 * scale,
      spacing: 2.0 * scale,
      children: generatedChildren,
    );
  }

  Widget buildImagePart(double scale) {
    bool frosthavenStyle = GameMethods.isFrosthavenStyle(widget.data.type);
    return Row(children: [
      Container(
          margin: EdgeInsets.only(right: 4 * scale),
          child: PhysicalShape(
            color: widget.data.turnState == TurnsState.current
                ? Colors.tealAccent
                : Colors.transparent,
            //or bleu if current
            shadowColor: Colors.black,
            elevation: 8,
            clipper: const ShapeBorderClipper(shape: CircleBorder()),
            child: Image(
              fit: BoxFit.contain,
              image: AssetImage(
                  "assets/images/monsters/${widget.data.type.gfx}.png"),
              //width: widget.height*SCALE_FACTOR,
            ),
          )),
      Container(
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.only(bottom: frosthavenStyle ? 2 * scale : 0),
          child: Text(
            textAlign: TextAlign.center,
            widget.data.type.display,
            style: TextStyle(
                fontFamily: frosthavenStyle ? "GermaniaOne" : 'Pirata',
                color: Colors.white,
                fontSize: 14.4 * scale,
                shadows: [
                  Shadow(
                    offset: Offset(1 * scale, 1 * scale),
                    color: Colors.black87,
                    blurRadius: 1 * scale,
                  )
                ]),
          ))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    double scale = getScaleByReference(context);
    var colorFilter = (widget.data.monsterInstances.value.isNotEmpty ||
                widget.data.isActive) &&
            (widget.data.turnState != TurnsState.done ||
                getIt<GameState>().roundState.value ==
                    RoundState.chooseInitiative)
        ? ColorFilter.matrix(identity)
        : ColorFilter.matrix(grayScale);
    var width = getMainListWidth(context);
    return ValueListenableBuilder<int>(
        valueListenable: getIt<GameState>().updateList,
        // widget.data.monsterInstances,
        builder: (context, value, child) {
          return Column(mainAxisSize: MainAxisSize.max, children: [
            ColorFiltered(
                colorFilter: colorFilter,
                child: SizedBox(
                  height: 25 * SCALE_FACTOR * scale,
                  width: width,
                  child: Row(
                    children: [
                      getIt<GameState>().roundState.value ==
                                  RoundState.playTurns &&
                              (widget.data.monsterInstances.value.isNotEmpty ||
                                  widget.data.isActive)
                          ? InkWell(
                              onTap: () {
                                getIt<GameState>()
                                    .action(TurnDoneCommand(widget.data.id));
                              },
                              child: buildImagePart(scale))
                          : buildImagePart(scale),
                    ],
                  ),
                )),
            ColorFiltered(
                colorFilter: colorFilter,
                child: SizedBox(
                  height: 160 * SCALE_FACTOR * scale,
                  //this dictates size of the cards
                  width: width,
                  child: Row(
                    children: [
                      MonsterAbilityCardWidget(data: widget.data),
                      MonsterStatCardWidget(data: widget.data),
                    ],
                  ),
                )),
            Container(
              //color: Colors.amber,
              //height: 50,
              margin: EdgeInsets.only(
                  left: 4 * scale * SCALE_FACTOR,
                  right: 4 * scale * SCALE_FACTOR),
              width: width - 4 * scale * SCALE_FACTOR,
              child: ValueListenableBuilder<int>(
                  valueListenable: getIt<GameState>().killMonsterStandee,
                  // widget.data.monsterInstances,
                  builder: (context, value, child) {
                    return buildMonsterBoxGrid(scale);
                  }),
            ),
          ]);
        });
  }
}
