import 'package:fpdart/fpdart.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/core/common/domain/models/event.dart';

abstract class EventRepository {
  Stream<Either<Failure, List<Event>>> getUpcomingEvents();
  Future<Either<Failure, Event>> createEvent(Event event);
  Future<Either<Failure, Event>> updateEvent(Event event);
  Future<Either<Failure, Unit>> deleteEvent(String eventId);
}
