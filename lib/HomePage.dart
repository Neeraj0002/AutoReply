import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:custom_switch/custom_switch.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms/sms.dart';

class HomePaage extends StatefulWidget {
  @override
  _HomePaageState createState() => _HomePaageState();
}

class _HomePaageState extends State<HomePaage> {
  Future<List<CallLogEntry>> getCallDetails() async {
    Iterable<CallLogEntry> entries = await CallLog.get();
    var now = DateTime.now();
    int to = now.millisecondsSinceEpoch;
    int from = now.subtract(Duration(minutes: 30)).millisecondsSinceEpoch;
    entries =
        await CallLog.query(type: CallType.missed, dateFrom: from, dateTo: to);

    return entries.toList();
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Timer(Duration(minutes: 1), () {
      setState(() {});
    });
    if (checkBoxValue) {
      if (msgController.text.length != 0) {
        getCallDetails().then((entryValues) {
          getLatMsgDetails().then((lastCallDetails) {
            for (int i = 0; i < entryValues.length; i++) {
              if ((lastCallDetails['name'] != entryValues[i].name &&
                      lastCallDetails['phone'] != entryValues[i].number) ||
                  lastCallDetails['time'] != entryValues[i].timestamp) {
                sentSms(entryValues[i].number, msgController.text);
                prevMsg(entryValues[i].name, entryValues[i].number,
                    entryValues[i].timestamp);
              } else {
                print("BREAK");
                break;
              }
            }
          });
        });
      } else {
        print("Text is null");
      }
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

class CallLog {
  static const MethodChannel _channel =
      const MethodChannel('sk.fourq.call_log');

  /// Get all call history log entries. Permissions are handled automatically
  static Future<Iterable<CallLogEntry>> get() async {
    Iterable result = await _channel.invokeMethod('get', null);
    return result?.map((m) => CallLogEntry.fromMap(m));
  }

  /// Query call history log entries
  /// dateFrom: unix timestamp. precision in millis
  /// dateTo: unix timestamp. precision in millis
  /// durationFrom: minimal call length in seconds
  /// durationTo: minimal call length in seconds
  /// name: call participant name (present only if in contacts)
  /// number: call participant phone number
  /// type: value from [CallType] enum
  static Future<Iterable<CallLogEntry>> query({
    int dateFrom,
    int dateTo,
    int durationFrom,
    int durationTo,
    String name,
    String number,
    CallType type,
    String numbertype,
    String numberlabel,
    String cachedNumberType,
    String cachedNumberLabel,
    String cachedMatchedNumber,
  }) async {
    var params = {
      "dateFrom": dateFrom?.toString(),
      "dateTo": dateTo?.toString(),
      "durationFrom": durationFrom?.toString(),
      "durationTo": durationTo?.toString(),
      "name": name,
      "number": number,
      "type": type?.index == null ? null : (type.index + 1).toString(),
      "cachedNumberType": cachedNumberType,
      "cachedNumberLabel": cachedNumberLabel,
      "cachedMatchedNumber": cachedMatchedNumber,
    };
    Iterable records = await _channel.invokeMethod('query', params);
    return records?.map((m) => CallLogEntry.fromMap(m));
  }
}

/// PODO for one call log entry
class CallLogEntry {
  CallLogEntry({
    this.name,
    this.number,
    this.formattedNumber,
    this.callType,
    this.duration,
    this.timestamp,
    this.cachedNumberType,
    this.cachedNumberLabel,
  });

  String name;
  String number;
  String formattedNumber;
  CallType callType;
  int duration;
  int timestamp;
  int cachedNumberType;
  String cachedNumberLabel;
  String cachedMatchedNumber;

  CallLogEntry.fromMap(Map m) {
    name = m['name'];
    number = m['number'];
    formattedNumber = m['formattedNumber'];
    callType = m['callType'] < 1 || m['callType'] > 8
        ? CallType.unknown
        : CallType.values[m['callType'] - 1];
    duration = m['duration'];
    timestamp = m['timestamp'];
    cachedNumberType = m['cachedNumberType'];
    cachedNumberLabel = m['cachedNumberLabel'];
    cachedMatchedNumber = m['cachedMatchedNumber'];
  }
}

/// All possible call types
enum CallType {
  incoming,
  outgoing,
  missed,
  voiceMail,
  rejected,
  blocked,
  answeredExternally,
  unknown,
}
