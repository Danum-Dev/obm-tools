import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:obm_tools/obm_tools.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obm Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ObmPage(),
    );
  }
}

class ObmPage extends StatefulWidget {
  const ObmPage({super.key});

  @override
  State<ObmPage> createState() => _ObmPageState();
}

class _ObmPageState extends State<ObmPage> {
  String? time;
  String? timeZone;
  String? connections;
  bool? connected;
  String? ipAddress;
  List<MultiLevelString> myItems = [
    MultiLevelString(level1: "1"),
    MultiLevelString(level1: "2"),
    MultiLevelString(
      level1: "3",
      subLevel: [
        MultiLevelString(level1: "sub3-1"),
        MultiLevelString(level1: "sub3-2"),
      ],
    ),
    MultiLevelString(level1: "4")
  ];
  MultiLevelString selectedItems = MultiLevelString(level1: "1");

  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController currencyController = TextEditingController();
  @override
  void initState() {
    setState(() {
      timeZone = "Asia/Jakarta";
    });
    initialApp();
    super.initState();
  }

  initialApp() async {
    getTimeZone();
    Timer.periodic(const Duration(milliseconds: 1), (timer) async {
      var connect = await checkConnection();
      setState(() {
        connected = connect;
      });
    });

    getIp();
  }

  // get time by timezone
  getTimeZone() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      DateTime dateTime = await ObmTools().getDateTime(timeZone ?? "Asia/Jakarta");
      setState(() {
        time = DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime);
      });
    });
  }

  // get connectifity
  Future<bool> checkConnection() async {
    var connectivityResult = await ObmTools().connection();
    setState(() {
      connections = connectivityResult!.name;
    });
    // connectivityResult.name = "wifi" / "mobile"
    switch (connectivityResult!.name) {
      case "mobile":
        return true;
      case "wifi":
        return true;
      default:
        return false;
    }
  }

  // get ip address
  getIp() async {
    var ip = await ObmTools().getIpAddress();
    setState(() {
      ipAddress = ip;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Form(
                key: formkey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        "TIME ZONE : ${timeZone ?? "..."}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        time ?? "...",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Icon(
                      connected ?? false ? Icons.wifi_outlined : Icons.wifi_off_outlined,
                      size: 50.0,
                      color: connected ?? false ? Colors.green : Colors.red,
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        "Connection : ${connections ?? "..."}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        "IP Address : ${ipAddress ?? "..."}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    // email text form field
                    ObmTextFormField(
                      controller: emailController,
                      autoFocus: false,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      labelText: "Email",
                      validator: (input) {
                        if (input!.isEmpty) {
                          return "Input your email";
                        } else {
                          // email validator
                          if (!(EmailValidator.validate(input))) {
                            return "Input your valid Email";
                          } else {
                            return null;
                          }
                        }
                      },
                      prefixIcon: const Icon(
                        Icons.account_circle_outlined,
                        color: Colors.black,
                      ),
                      hintText: "Email",
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    // custom text form field with currency formater
                    ObmTextFormField(
                      controller: currencyController,
                      autoFocus: false,
                      isCurrency: true,
                      prefixText: currencyController.text.isEmpty ? '' : 'Rp ',
                      currencyCodeZone: "id_ID",
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      labelText: "Amount Money",
                      validator: (input) {
                        if (input!.isEmpty) {
                          return "Input your amount money";
                        } else {
                          return null;
                        }
                      },
                      hintText: "Rp 1.500.000",
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    // custom button
                    ObmButton(
                      buttonLabel: "Submit",
                      buttonWidth: double.infinity,
                      buttonColor: Colors.orange,
                      borderRadius: 5.0,
                      press: () {
                        submit();
                      },
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    // dropdown search
                    ObmDropDownSearch<MultiLevelString>(
                      items: myItems,
                      labelText: "",
                      showSearchBox: true,
                      hintColor: Colors.black12,
                      fontColor: Colors.black,
                      onChanged: (value) {
                        setState(() {
                          selectedItems = value!;
                        });
                      },
                      validator: (input) {
                        if (input == null) {
                          return "Select your choice";
                        } else {
                          return null;
                        }
                      },
                      selectedItem: selectedItems,
                      itemAsString: (MultiLevelString u) => u.level1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  submit() {
    if (formkey.currentState!.validate()) {}
  }
}

class MultiLevelString {
  final String level1;
  final List<MultiLevelString> subLevel;
  bool isExpanded;

  MultiLevelString({
    this.level1 = "",
    this.subLevel = const [],
    this.isExpanded = false,
  });

  MultiLevelString copy({
    String? level1,
    List<MultiLevelString>? subLevel,
    bool? isExpanded,
  }) =>
      MultiLevelString(
        level1: level1 ?? this.level1,
        subLevel: subLevel ?? this.subLevel,
        isExpanded: isExpanded ?? this.isExpanded,
      );

  @override
  String toString() => level1;
}
