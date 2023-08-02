import 'package:repository/model/cloud/household.dart';

abstract class HouseholdDatabase {
  Household? get household;
  Household create();
  void leave();
}
