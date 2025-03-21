import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';
import 'transition.dart';
import 'bloc_supervisor.dart';

abstract class Bloc<Event, State> {
  //base para otras Bloc específicas
  final PublishSubject<Event> _eventSubject =
      PublishSubject<Event>(); //recibe los eventos con .sink.add(event).
  late BehaviorSubject<State>
  _stateSubject; //guarda el estado actual y permite que otros componentes escuchen cambios

  State get initialState; //será definido en las clases hijas

  State get currentState => _stateSubject.value; //valor actual

  Stream<State> get state => _stateSubject.stream; //cambios de estado

  Bloc() {
    _stateSubject = BehaviorSubject<State>.seeded(initialState);
    _bindStateSubject();
  }

  @mustCallSuper
  void dispose() {
    _eventSubject.close();
    _stateSubject.close();
  }

  void onTransition(Transition<Event, State> transition) => null;

  void onError(Object error, StackTrace stacktrace) => null;

  void onEvent(Event event) => null;

  void dispatch(Event event) {
    //meter eventos en eventSubject, ENTRADAS
    try {
      BlocSupervisor.delegate.onEvent(this, event);
      onEvent(event);
      _eventSubject.sink.add(event);
    } catch (error) {
      _handleError(error);
    }
  } //Llama a onEvent(), luego agrega el evento al _eventSubject. Si hay un error, lo maneja con _handleError().

  Stream<State> transform(
    Stream<Event> events,
    Stream<State> Function(Event) next,
  ) {
    return events.asyncExpand(next);
  }

  Stream<State> mapEventToState(Event event); //en hijas

  void _bindStateSubject() {
    Event? currentEvent;

    transform(_eventSubject, (Event event) {
      currentEvent = event;
      return mapEventToState(currentEvent!).handleError(_handleError);
    }).forEach((State nextState) {
      if (currentState == nextState || _stateSubject.isClosed) return;
      final transition = Transition(
        currentState: currentState,
        event: currentEvent!,
        nextState: nextState,
      );
      BlocSupervisor.delegate.onTransition(this, transition);
      onTransition(transition);
      _stateSubject.sink.add(nextState);
    });
  } // Usa transform() para mapear eventos a estados y emite los nuevos estados en _stateSubject.

  void _handleError(Object error, [StackTrace? stacktrace]) {
    if (stacktrace != null) {
      BlocSupervisor.delegate.onError(this, error, stacktrace);
      onError(error, stacktrace);
    }
  }
}
