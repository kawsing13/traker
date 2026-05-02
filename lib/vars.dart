import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

bool internetUp = false;
bool isSyncing = false;
bool isOnline = false;
bool isLoggedIn = false;
int userId = 0;
int empId = 0;
int maxClientId = 0;
int ClientId = 0;
String fullName = "";
String userName = "";
String companyName = "";
String areaName = "";

const focusedBorderColor = Color.fromRGBO(23, 171, 144, 1);
const fillColor = Color.fromRGBO(243, 246, 249, 0);
const borderColor = Color.fromRGBO(23, 171, 144, 0.4);

final defaultPinTheme = PinTheme(
  width: 56,
  height: 56,
  textStyle: const TextStyle(
    fontSize: 22,
    color: Color.fromRGBO(30, 60, 87, 1),
  ),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(19),
    border: Border.all(color: borderColor),
  ),
);

enum EducLevel {
  HG('Highschool Graduate'),
  KG('K-12 Graduate'),
  AG('Associate Graudate (2 years diploma)'),
  BD('Bachelor\'s Degree (4-5 years)'),
  MD('Master\'s Degree'),
  DD('Doctorate Degree');

  const EducLevel(this.label);
  final String label;
}

// DropdownMenuEntry labels and values for the second dropdown menu.
enum CivilStatus {
  Single('Single'),
  Married('Married'),
  Divorsed('Divorsed'),
  Separated('Separated'),
  Widow('Widow'),
  Widower('Widower'),
  LiveIn('Live In'),
  CommonLaw('Common Law');

  const CivilStatus(this.label);
  final String label;
}

enum Service {
  StudentVisa('Student Visa'),
  ImmigrantVisa('Immigrant Visa');

  const Service(this.label);
  final String label;
}

enum PayMethods {
  Cash('Cash'),
  Check('Check'),
  Electronic('Electronic');

  const PayMethods(this.label);
  final String label;
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
