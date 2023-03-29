library obm_tools;

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzl;
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;

/// That contains many tools for the application.
class ObmTools {
  /// Find [Location] by its timezone name
  getDateTime(String? timeZone) {
    tzl.initializeTimeZones();
    final detroit = tz.getLocation(timeZone ?? 'Asia/Jakarta');
    var now = tz.TZDateTime.now(detroit);
    return now;
  }

  /// Check device internet connection
  Future<ConnectivityResult?> connection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult;
  }

  /// Get IP Address
  Future<String?> getIpAddress() async {
    try {
      final url = Uri.parse('https://api.ipify.org');
      final response = await http.get(url);
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      try {
        final url = Uri.parse('https://ipwhois.app/json/');
        final response = await http.get(url);
        final jsonResponse = jsonDecode(response.body);
        return response.statusCode == 200 ? jsonResponse['ip'] : null;
      } catch (e) {
        return null;
      }
    }
  }
}

enum SubdomainType { none, alphabetic, numeric, alphanumeric }

/// Email validator
class EmailValidator {
  static int _index = 0;
  static const String _atomCharacters = "!#\$%&'*+-/=?^_`{|}~";
  static SubdomainType _domainType = SubdomainType.none;
  static bool _isDigit(String c) {
    return c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  }

  static bool _isLetter(String c) {
    return (c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90) ||
        (c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122);
  }

  static bool _isLetterOrDigit(String c) {
    return _isLetter(c) || _isDigit(c);
  }

  static bool _isAtom(String c, bool allowInternational) {
    return c.codeUnitAt(0) < 128
        ? _isLetterOrDigit(c) || _atomCharacters.contains(c)
        : allowInternational;
  }

  static bool _isDomain(String c, bool allowInternational) {
    if (c.codeUnitAt(0) < 128) {
      if (_isLetter(c) || c == '-') {
        _domainType = SubdomainType.alphabetic;
        return true;
      }

      if (_isDigit(c)) {
        _domainType = SubdomainType.numeric;
        return true;
      }

      return false;
    }

    if (allowInternational) {
      _domainType = SubdomainType.alphabetic;
      return true;
    }

    return false;
  }

  static bool _isDomainStart(String c, bool allowInternational) {
    if (c.codeUnitAt(0) < 128) {
      if (_isLetter(c)) {
        _domainType = SubdomainType.alphabetic;
        return true;
      }

      if (_isDigit(c)) {
        _domainType = SubdomainType.numeric;
        return true;
      }

      _domainType = SubdomainType.none;

      return false;
    }

    if (allowInternational) {
      _domainType = SubdomainType.alphabetic;
      return true;
    }

    _domainType = SubdomainType.none;

    return false;
  }

  static bool _skipAtom(String text, bool allowInternational) {
    final startIndex = _index;

    while (_index < text.length && _isAtom(text[_index], allowInternational)) {
      _index++;
    }

    return _index > startIndex;
  }

  static bool _skipSubDomain(String text, bool allowInternational) {
    final startIndex = _index;

    if (!_isDomainStart(text[_index], allowInternational)) {
      return false;
    }

    _index++;

    while (_index < text.length && _isDomain(text[_index], allowInternational)) {
      _index++;
    }

    return (_index - startIndex) < 64 && text[_index - 1] != '-';
  }

  static bool _skipDomain(String text, bool allowTopLevelDomains, bool allowInternational) {
    if (!_skipSubDomain(text, allowInternational)) {
      return false;
    }

    if (_index < text.length && text[_index] == '.') {
      do {
        _index++;

        if (_index == text.length) {
          return false;
        }

        if (!_skipSubDomain(text, allowInternational)) {
          return false;
        }
      } while (_index < text.length && text[_index] == '.');
    } else if (!allowTopLevelDomains) {
      return false;
    }
    if (_domainType == SubdomainType.numeric) {
      return false;
    }

    return true;
  }

  static bool _skipQuoted(String text, bool allowInternational) {
    var escaped = false;

    _index++;

    while (_index < text.length) {
      if (text[_index].codeUnitAt(0) >= 128 && !allowInternational) {
        return false;
      }

      if (text[_index] == '\\') {
        escaped = !escaped;
      } else if (!escaped) {
        if (text[_index] == '"') {
          break;
        }
      } else {
        escaped = false;
      }

      _index++;
    }

    if (_index >= text.length || text[_index] != '"') {
      return false;
    }

    _index++;

    return true;
  }

  static bool _skipIPv4Literal(String text) {
    var groups = 0;

    while (_index < text.length && groups < 4) {
      final startIndex = _index;
      var value = 0;

      while (_index < text.length &&
          text[_index].codeUnitAt(0) >= 48 &&
          text[_index].codeUnitAt(0) <= 57) {
        value = (value * 10) + (text[_index].codeUnitAt(0) - 48);
        _index++;
      }

      if (_index == startIndex || _index - startIndex > 3 || value > 255) {
        return false;
      }

      groups++;

      if (groups < 4 && _index < text.length && text[_index] == '.') {
        _index++;
      }
    }

    return groups == 4;
  }

  static bool _isHexDigit(String str) {
    final c = str.codeUnitAt(0);
    return (c >= 65 && c <= 70) || (c >= 97 && c <= 102) || (c >= 48 && c <= 57);
  }

  static bool _skipIPv6Literal(String text) {
    var compact = false;
    var colons = 0;

    while (_index < text.length) {
      var startIndex = _index;

      while (_index < text.length && _isHexDigit(text[_index])) {
        _index++;
      }

      if (_index >= text.length) {
        break;
      }

      if (_index > startIndex && colons > 2 && text[_index] == '.') {
        _index = startIndex;

        if (!_skipIPv4Literal(text)) {
          return false;
        }

        return compact ? colons < 6 : colons == 6;
      }

      var count = _index - startIndex;
      if (count > 4) {
        return false;
      }

      if (text[_index] != ':') {
        break;
      }

      startIndex = _index;
      while (_index < text.length && text[_index] == ':') {
        _index++;
      }

      count = _index - startIndex;
      if (count > 2) {
        return false;
      }

      if (count == 2) {
        if (compact) {
          return false;
        }

        compact = true;
        colons += 2;
      } else {
        colons++;
      }
    }

    if (colons < 2) {
      return false;
    }

    return compact ? colons < 7 : colons == 7;
  }

  static bool validate(String email,
      [bool allowTopLevelDomains = false, bool allowInternational = true]) {
    _index = 0;

    if (email.isEmpty || email.length >= 255) {
      return false;
    }
    if (email[_index] == '"') {
      if (!_skipQuoted(email, allowInternational) || _index >= email.length) {
        return false;
      }
    } else {
      if (!_skipAtom(email, allowInternational) || _index >= email.length) {
        return false;
      }

      while (email[_index] == '.') {
        _index++;

        if (_index >= email.length) {
          return false;
        }

        if (!_skipAtom(email, allowInternational)) {
          return false;
        }

        if (_index >= email.length) {
          return false;
        }
      }
    }

    if (_index + 1 >= email.length || _index > 64 || email[_index++] != '@') {
      return false;
    }

    if (email[_index] != '[') {
      if (!_skipDomain(email, allowTopLevelDomains, allowInternational)) {
        return false;
      }

      return _index == email.length;
    }
    _index++;
    if (_index + 8 >= email.length) {
      return false;
    }

    final ipv6 = email.substring(_index - 1).toLowerCase();

    if (ipv6.contains('ipv6:')) {
      _index += 'IPv6:'.length;
      if (!_skipIPv6Literal(email)) {
        return false;
      }
    } else {
      if (!_skipIPv4Literal(email)) {
        return false;
      }
    }

    if (_index >= email.length || email[_index++] != ']') {
      return false;
    }

    return _index == email.length;
  }
}

/// Custom Button Widget
class ObmButton extends StatelessWidget {
  const ObmButton({
    Key? key,
    this.buttonLabel,
    this.buttonColor,
    this.labelColor,
    this.labelSize,
    this.press,
    this.paddingButton,
    this.borderRadius,
    this.buttonWidth,
    this.buttonHeight,
    this.btnBorderColor,
    this.borderWidth,
    this.boxShadow,
    this.iconLead,
    this.iconLeadColor,
    this.iconLeadSize,
    this.alignText,
    this.mainAxisAlignment,
    this.isLoadingSearch,
  }) : super(key: key);
  final String? buttonLabel;
  final Color? buttonColor;
  final Color? labelColor;
  final double? labelSize;
  final Function()? press;
  final double? paddingButton;
  final double? borderRadius;
  final double? buttonWidth;
  final double? buttonHeight;
  final Color? btnBorderColor;
  final double? borderWidth;
  final List<BoxShadow>? boxShadow;
  final IconData? iconLead;
  final Color? iconLeadColor;
  final double? iconLeadSize;
  final TextAlign? alignText;
  final MainAxisAlignment? mainAxisAlignment;
  final bool? isLoadingSearch;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Container(
        width: buttonWidth ?? double.infinity,
        height: buttonHeight,
        decoration: BoxDecoration(
          color: buttonColor == null ? Colors.white : buttonColor!,
          borderRadius: BorderRadius.all(
            Radius.circular(
              borderRadius == null ? 32.0 : borderRadius!,
            ),
          ),
          border: Border.all(
            color: btnBorderColor == null ? Colors.transparent : btnBorderColor!,
            width: borderWidth ?? 1.0,
          ),
          boxShadow: boxShadow ?? [],
        ),
        child: Padding(
          padding: EdgeInsets.all(
            paddingButton == null ? 15.0 : paddingButton!,
          ),
          child: Row(
            mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.center,
            children: [
              iconLead != null
                  ? Icon(
                      iconLead,
                      color: iconLeadColor ?? const Color(0xFF000000),
                      size: iconLeadSize,
                    )
                  : const SizedBox(),
              iconLead != null && (buttonLabel ?? '') != ''
                  ? const SizedBox(
                      width: 13.0,
                    )
                  : const SizedBox(),
              isLoadingSearch ?? false
                  ? const SizedBox(height: 20.0, width: 20.0, child: CircularProgressIndicator())
                  : (buttonLabel ?? '') == ''
                      ? const SizedBox()
                      : Text(
                          buttonLabel!,
                          textAlign: alignText ?? TextAlign.center,
                          style: TextStyle(
                            color: labelColor == null ? Colors.white : labelColor!,
                            fontSize: labelSize ?? 16,
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Text Form Field Widget
class ObmTextFormField extends StatelessWidget {
  const ObmTextFormField({
    Key? key,
    this.controller,
    this.focusTo,
    this.focusNode,
    this.keyboardType,
    this.obscureText,
    this.suffixIcon,
    this.prefixIcon,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.autoFocus,
    this.maxLines,
    this.isCurrency,
    this.prefixText,
    this.enabled,
    this.lengthLimit,
    this.filled,
    this.fillColor,
    this.onTap,
    this.textColor,
    this.hintTextColor,
    this.borderColor,
    this.disabledBorderColor,
    this.focusedBorderColor,
    this.currencyCodeZone,
  }) : super(key: key);
  final TextEditingController? controller;
  final FocusNode? focusTo;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool? obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final String? labelText;
  final String? hintText;
  final bool? autoFocus;
  final int? maxLines;
  final bool? isCurrency;
  final String? prefixText;
  final bool? enabled;
  final int? lengthLimit;
  final bool? filled;
  final Color? fillColor;
  final Function()? onTap;
  final Color? textColor;
  final Color? hintTextColor;
  final Color? borderColor;
  final Color? disabledBorderColor;
  final Color? focusedBorderColor;
  final String? currencyCodeZone;

  @override
  Widget build(BuildContext context) {
    return obscureText == null
        ? TextFormField(
            onTap: onTap ?? () {},
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            maxLines: maxLines,
            maxLength: lengthLimit,
            focusNode: focusNode,
            controller: controller,
            keyboardType: keyboardType ?? TextInputType.text,
            validator: validator,
            autofocus: autoFocus ?? false,
            enabled: enabled ?? true,
            style: TextStyle(
              fontSize: 16.0,
              color: textColor ?? Colors.black,
            ),
            decoration: InputDecoration(
              counterText: '',
              fillColor: fillColor ?? Colors.white,
              filled: filled ?? false,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 20.0,
              ),
              labelText: labelText ?? 'Form',
              labelStyle: TextStyle(
                color: textColor ?? Colors.black,
                fontSize: 16.0,
                fontWeight: FontWeight.w400,
              ),
              hintText: hintText ?? 'Form',
              hintStyle: TextStyle(
                color: hintTextColor ?? Colors.grey.withOpacity(0.7),
                fontSize: 16.0,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: borderColor ?? Colors.black),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: disabledBorderColor ?? Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: focusedBorderColor ?? Colors.blue),
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon ?? const SizedBox(),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                color: textColor ?? Colors.black,
              ),
            ),
            onChanged: onChanged,
            textInputAction: textInputAction,
            onFieldSubmitted: (v) {
              focusTo != null ? FocusScope.of(context).requestFocus(focusTo) : null;
            },
            inputFormatters: isCurrency ?? false
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyFormatForm(currencyCodeZone ?? "id_ID"),
                  ]
                : [],
          )
        : TextFormField(
            onTap: onTap ?? () {},
            focusNode: focusNode,
            controller: controller,
            obscureText: obscureText ?? false,
            keyboardType: keyboardType ?? TextInputType.text,
            validator: validator,
            autofocus: autoFocus ?? false,
            style: TextStyle(
              fontSize: 16.0,
              color: textColor ?? Colors.black,
            ),
            decoration: InputDecoration(
              fillColor: fillColor ?? Colors.white,
              filled: filled ?? false,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 20.0,
              ),
              labelText: labelText ?? 'Form',
              labelStyle: TextStyle(
                color: textColor ?? Colors.black,
                fontSize: 16.0,
                fontWeight: FontWeight.w400,
              ),
              hintText: hintText ?? 'Form',
              hintStyle: TextStyle(
                color: hintTextColor ?? Colors.grey.withOpacity(0.7),
                fontSize: 16.0,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: borderColor ?? Colors.black),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: disabledBorderColor ?? Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: focusedBorderColor ?? Colors.blue),
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon ?? const SizedBox(),
              prefixStyle: TextStyle(color: textColor ?? Colors.black),
            ),
            onChanged: onChanged,
            textInputAction: textInputAction,
            onFieldSubmitted: (v) {
              focusTo != null ? FocusScope.of(context).requestFocus(focusTo) : null;
            },
          );
  }
}

/// Form currency formater
class CurrencyFormatForm extends TextInputFormatter {
  String currencyCode;
  CurrencyFormatForm(this.currencyCode);
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    double value = double.parse(newValue.text);
    String newText = NumberFormat("###,###,###", currencyCode).format(value);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length,
      ),
    );
  }
}

/// Custom Drop Down Search Form

class ObmDropDownSearch<T> extends StatelessWidget {
  const ObmDropDownSearch({
    Key? key,
    this.showSearchBox,
    this.items,
    this.enabled,
    this.filled,
    this.onChanged,
    this.selectedItem,
    this.itemAsString,
    this.validator,
    this.labelText,
    this.fontColor,
    this.hintColor,
    this.fillColor,
  }) : super(key: key);
  final bool? showSearchBox;
  final List<T>? items;
  final bool? enabled;
  final bool? filled;
  final Function(T?)? onChanged;
  final T? selectedItem;
  final String Function(T)? itemAsString;
  final String? Function(T?)? validator;
  final String? labelText;
  final Color? fontColor;
  final Color? hintColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return items!.isEmpty
        ? const SizedBox()
        : IgnorePointer(
            ignoring: !(enabled ?? true),
            child: DropdownSearch<T>(
              popupProps: PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    fillColor: fillColor ?? Colors.white,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 20.0,
                    ),
                    hintText: 'Cari',
                    hintStyle: TextStyle(
                      color: hintColor ?? hintColor,
                      fontSize: 17.0,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              items: items ?? [],
              itemAsString: itemAsString,
              dropdownDecoratorProps: DropDownDecoratorProps(
                baseStyle: TextStyle(
                  color: fontColor ?? Colors.black,
                  fontSize: 17,
                ),
                dropdownSearchDecoration: InputDecoration(
                  enabled: !(enabled ?? true),
                  filled: filled ?? false,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 20.0,
                  ),
                  labelText: labelText ?? '...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              onChanged: onChanged ?? (newValue) {},
              selectedItem: selectedItem,
              validator: validator ??
                  (value) {
                    return null;
                  },
            ),
          );
  }
}
