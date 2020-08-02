import 'dart:async';
import 'dart:convert';
import 'package:call_log/call_log.dart';
import 'package:custom_switch/custom_switch.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms/sms.dart';

class HomePaage extends StatefulWidget {
  @override
  _HomePaageState createState() => _HomePaageState();
}

class _HomePaageState extends State<HomePaage> {
  Future askPermissionPhone() async {
    if (await Permission.phone.isDenied ||
        await Permission.phone.isUndetermined ||
        await Permission.phone.isRestricted) {
      print("REQUESTING PHOENE");
      Permission.phone.request();
    }
  }

  Future askSmsPermission() async {
    if (await Permission.sms.isDenied ||
        await Permission.sms.isUndetermined ||
        await Permission.sms.isRestricted) {
      print("REQUESTING SMS");
      Permission.sms.request();
    }
  }

  Future<List<CallLogEntry>> getCallDetails() async {
    Iterable<CallLogEntry> entries1 = await CallLog.get();
    var now = DateTime.now();
    int to = now.millisecondsSinceEpoch;
    int from = now.subtract(Duration(minutes: 30)).millisecondsSinceEpoch;
    entries1 =
        await CallLog.query(type: CallType.missed, dateFrom: from, dateTo: to);
    return entries1.toList();
  }

  sentSms(String number, String messageText) async {
    SmsSender sender = new SmsSender();
    String address = number;
    SmsMessage message = new SmsMessage(address, messageText);
    message.onStateChanged.listen((state) {
      if (state == SmsMessageState.Sent) {
        print("SMS is sent!");
      } else if (state == SmsMessageState.Delivered) {
        print("SMS is delivered!");
      } else if (state == SmsMessageState.Fail) {
        print("Failed in sending SMS :(");
      }
    });
    sender.sendSms(message);
  }

  Future prevMsg(String name, String phoneNo, int time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map lastCallDetail = {"name": name, "phone": phoneNo, "time": time};
    prefs.setString("lastMsg", jsonEncode(lastCallDetail));
    return "done";
  }

  getLatMsgDetails<Map>() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastCall = prefs.getString("lastMsg");

    return lastCall != null
        ? jsonDecode(lastCall)
        : {"name": null, "phone": null, "time": null};
  }

  setMsgText(String msgText) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(msgText);
    prefs.setString('msgText', msgText).then((value) => print("Text is set"));
  }

  Future<String> getMsgText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String msgtext = prefs.getString("msgText");
    return msgtext != null
        ? msgtext
        : "Hi,\nI'm busy at the moment I'll call you back soon.";
  }

  TextEditingController msgController = TextEditingController();
  bool checkBoxValue;
  @override
  void initState() {
    checkBoxValue = false;
    getMsgText().then((value) {
      setState(() {
        msgController.text = value;
      });
    });
    //askPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Timer(Duration(minutes: 1), () {
      setState(() {});
    });

    if (msgController.text.length != 0) {
      getCallDetails().then((entryValues) {
        getLatMsgDetails().then((lastCallDetails) {
          askPermissionPhone().then((value) {
            for (int i = 0; i < entryValues.length; i++) {
              if ((lastCallDetails['name'] != entryValues[i].name &&
                      lastCallDetails['phone'] != entryValues[i].number) ||
                  lastCallDetails['time'] != entryValues[i].timestamp) {
                if (checkBoxValue) {
                  sentSms(entryValues[i].number, msgController.text);
                  prevMsg(entryValues[i].name, entryValues[i].number,
                      entryValues[i].timestamp);
                }
              } else {
                print("BREAK");
                break;
              }
            }
          });
        });
      });
    } else {
      print("Text is null");
    }

    return SafeArea(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
          setMsgText(msgController.text);
        },
        child: Scaffold(
          backgroundColor: Color.fromRGBO(47, 43, 67, 1.0),
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            title: Text(
              "Auto Reply",
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: "Abel",
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
            backgroundColor: Color.fromRGBO(57, 51, 81, 1.0),
          ),
          body: Stack(children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Turn on auto reply",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: "Abel"),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    CustomSwitch(
                      activeColor: Color.fromRGBO(240, 173, 120, 1.0),
                      value: checkBoxValue,
                      onChanged: (value) {
                        setState(() {
                          checkBoxValue = value;
                        });
                      },
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Color.fromRGBO(240, 173, 120, 1.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        onSubmitted: (value) {
                          setMsgText(value);
                        },
                        onChanged: (value) {
                          setMsgText(value);
                        },
                        controller: msgController,
                        maxLines: 4,
                        cursorColor: Color.fromRGBO(57, 51, 81, 1.0),
                        style: TextStyle(
                            color: Colors.white, fontFamily: "Lobster"),
                        decoration: InputDecoration(
                            hintStyle: TextStyle(
                                color: Colors.white, fontFamily: "Abel"),
                            hintText: "Enter Message Here",
                            border: InputBorder.none),
                      ),
                    ),
                  ),
                )
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "work.nrj@gmail.com",
                  style: TextStyle(
                    color: Color.fromRGBO(62, 60, 90, 1.0),
                    fontFamily: "Abel",
                    fontSize: 20,
                  ),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
