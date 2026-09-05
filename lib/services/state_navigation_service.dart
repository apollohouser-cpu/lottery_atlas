import '../models/state_model.dart';

class StateNavigationService {
  static StateModel? getStateByAbbreviation(String abbreviation) {
    try {
      return allStates.firstWhere(
        (state) =>
            state.abbreviation.toUpperCase() == abbreviation.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static StateModel? getStateByName(String name) {
    try {
      return allStates.firstWhere(
        (state) => state.name.toUpperCase() == name.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
