<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

## Getting started

### Installing
Add this to your package's `pubspec.yaml` file:
```yaml
dependencies:
  obm_tools: ^latest
```
### Import
```dart
import 'package:obm_tools/obm_tools.dart';
```
## Usage

### get time by timezone
```dart
getTimeZone() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
        DateTime dateTime = await ObmTools().getDateTime(timeZone ?? "Asia/Jakarta");
        setState(() {
            time = DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime);
        });
    });
}
```

### get connectifity
```dart
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
```

### get ip address
```dart
getIp() async {
    var ip = await ObmTools().getIpAddress();
    setState(() {
      ipAddress = ip;
    });
}
```

### Custom Text Form Field widget and Email Validator
```dart
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
```

### Custom Text Form Field with currency formater
```dart
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
```

### Custom Button
```dart
ObmButton(
    buttonLabel: "Submit",
    buttonWidth: double.infinity,
    buttonColor: Colors.orange,
    borderRadius: 5.0,
    press: () {
    submit();
    },
),
```