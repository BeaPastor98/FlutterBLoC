import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class Transition<Event, State> extends Equatable {
  final State currentState;
  final Event event;
  final State nextState;

  Transition({
    required this.currentState,
    required this.event,
    required this.nextState,
  }) : super();

  @override
  List<Object?> get props => [currentState, event, nextState];

  @override
  String toString() =>
      'Transition { currentState: $currentState, event: $event, nestState: $nextState}';
}
