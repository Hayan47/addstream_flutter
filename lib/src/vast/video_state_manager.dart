import 'vast_models.dart';

class VideoStateManager {
  VideoAdState _currentState = VideoAdState.uninitialized;

  VideoAdState get currentState => _currentState;

  void updateState(VideoAdState newState) => _currentState = newState;

  bool isInState(VideoAdState state) => _currentState == state;
}
