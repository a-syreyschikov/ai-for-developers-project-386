import "@typespec/http";
import "@typespec/json-schema";
import "@typespec/openapi";
import "@typespec/openapi3";

using TypeSpec.Http;
using TypeSpec.OpenAPI;

@service(#{ title: "Calendar API" })
@info(#{ version: "0.1.0" })
@server("http://localhost:8080", "Local development server")
@route("/api")
namespace Calendar;

@doc("Server-generated UUID string.")
@format("uuid")
scalar ResourceId extends string;

@doc("A UTC timestamp with Z suffix. The API accepts minute precision only; seconds and milliseconds must be zero.")
scalar UtcMinuteDateTime extends utcDateTime;

@doc("Machine-readable domain error code.")
enum ErrorCode {
  VALIDATION_FAILED,
  EVENT_TYPE_NOT_FOUND,
  BOOKING_NOT_FOUND,
  AVAILABILITY_WINDOW_NOT_FOUND,
  DUPLICATE_EVENT_TYPE_TITLE,
  AVAILABILITY_WINDOW_OVERLAP,
  SLOT_UNAVAILABLE,
  SLOT_OUTSIDE_BOOKING_WINDOW,
  BOOKING_NOT_CANCELLABLE,
}

@doc("Booking lifecycle status. Cancelled bookings do not block slots.")
enum BookingStatus {
  scheduled,
  cancelled,
}

@doc("RFC 7807 problem details with a domain-specific error code.")
@extension("x-example", #{
  type: "https://calendar.local/problems/slot-unavailable",
  title: "Slot is unavailable",
  status: 409,
  detail: "The selected time overlaps an existing scheduled booking.",
  code: "SLOT_UNAVAILABLE"
})
model ProblemDetails {
  @doc("URI reference that identifies the problem type.")
  type: string;

  @doc("Short human-readable problem title.")
  title: string;

  @doc("HTTP status code.")
  status: int32;

  @doc("Human-readable explanation specific to this occurrence.")
  detail?: string;

  @doc("Stable machine-readable error code.")
  code: ErrorCode;
}

@doc("Single preconfigured calendar owner used by owner and public APIs.")
@extension("x-example", #{
  id: "11111111-1111-1111-1111-111111111111",
  displayName: "Alex Owner",
  timeZone: "Europe/Moscow"
})
model Owner {
  @doc("Server-generated owner UUID.")
  id: ResourceId;

  @doc("Owner display name.")
  @minLength(1)
  @maxLength(120)
  displayName: string;

  @doc("IANA time zone name used for display, for example Europe/Moscow.")
  @minLength(1)
  timeZone: string;
}

@doc("Type of meeting that a guest can book.")
@extension("x-example", #{
  id: "22222222-2222-2222-2222-222222222222",
  title: "Intro call",
  description: "A short introductory call.",
  durationMinutes: 30
})
model EventType {
  @doc("Server-generated event type UUID.")
  id: ResourceId;

  @doc("Event type title. Titles are unique after trim and case-insensitive normalization.")
  @minLength(1)
  @maxLength(120)
  title: string;

  @doc("Event type description. The field is always present and may be an empty string.")
  @minLength(0)
  @maxLength(1000)
  description: string;

  @doc("Event duration in minutes. Must be between 15 and 240 and divisible by 15.")
  @minValue(15)
  @maxValue(240)
  @TypeSpec.JsonSchema.multipleOf(15)
  durationMinutes: int32;
}

@doc("Concrete UTC interval published by the owner as available time.")
@extension("x-example", #{
  id: "33333333-3333-3333-3333-333333333333",
  startsAt: "2026-06-15T07:00:00Z",
  endsAt: "2026-06-15T10:00:00Z"
})
model AvailabilityWindow {
  @doc("Server-generated availability window UUID.")
  id: ResourceId;

  @doc("Inclusive start of the half-open interval. Must be in the future and aligned to the 15-minute grid.")
  startsAt: UtcMinuteDateTime;

  @doc("Exclusive end of the half-open interval. Must be after startsAt and aligned to the 15-minute grid.")
  endsAt: UtcMinuteDateTime;
}

@doc("Computed free slot for a concrete event type. Slots are not persisted and have no id.")
@extension("x-example", #{
  eventTypeId: "22222222-2222-2222-2222-222222222222",
  startsAt: "2026-06-15T07:00:00Z",
  endsAt: "2026-06-15T07:30:00Z",
  durationMinutes: 30
})
model Slot {
  @doc("Event type UUID for which the slot was computed.")
  eventTypeId: ResourceId;

  @doc("Inclusive slot start in UTC. Must satisfy now < startsAt < now + 14 days.")
  startsAt: UtcMinuteDateTime;

  @doc("Exclusive slot end in UTC, computed from the event type duration.")
  endsAt: UtcMinuteDateTime;

  @doc("Event duration in minutes.")
  @minValue(15)
  @maxValue(240)
  @TypeSpec.JsonSchema.multipleOf(15)
  durationMinutes: int32;
}

@doc("Booking created by a guest for a computed free slot.")
@extension("x-example", #{
  id: "44444444-4444-4444-4444-444444444444",
  eventTypeId: "22222222-2222-2222-2222-222222222222",
  eventTypeTitle: "Intro call",
  durationMinutes: 30,
  startsAt: "2026-06-15T07:00:00Z",
  endsAt: "2026-06-15T07:30:00Z",
  guestName: "Guest User",
  guestEmail: "guest@example.com",
  status: "scheduled",
  createdAt: "2026-06-11T12:00:00Z"
})
model Booking {
  @doc("Server-generated booking UUID.")
  id: ResourceId;

  @doc("Booked event type UUID.")
  eventTypeId: ResourceId;

  @doc("Event type title copied for booking list rendering.")
  @minLength(1)
  @maxLength(120)
  eventTypeTitle: string;

  @doc("Booked event duration in minutes.")
  @minValue(15)
  @maxValue(240)
  @TypeSpec.JsonSchema.multipleOf(15)
  durationMinutes: int32;

  @doc("Inclusive booking start in UTC.")
  startsAt: UtcMinuteDateTime;

  @doc("Exclusive booking end in UTC.")
  endsAt: UtcMinuteDateTime;

  @doc("Guest name normalized with trim.")
  @minLength(1)
  @maxLength(120)
  guestName: string;

  @doc("Guest email normalized with trim and lower-case.")
  @format("email")
  @minLength(1)
  @maxLength(254)
  guestEmail: string;

  @doc("Current booking status.")
  status: BookingStatus;

  @doc("UTC timestamp when the booking was created.")
  createdAt: UtcMinuteDateTime;

  @doc("UTC timestamp when the owner cancelled the booking. Present only for cancelled bookings.")
  cancelledAt?: UtcMinuteDateTime;
}

@doc("Request to create an event type. The server generates id.")
@extension("x-example", #{
  title: "Intro call",
  description: "A short introductory call.",
  durationMinutes: 30
})
model CreateEventTypeRequest {
  @minLength(1)
  @maxLength(120)
  title: string;

  @minLength(0)
  @maxLength(1000)
  description: string;

  @minValue(15)
  @maxValue(240)
  @TypeSpec.JsonSchema.multipleOf(15)
  durationMinutes: int32;
}

@doc("Request to create an availability window. The server generates id.")
@extension("x-example", #{
  startsAt: "2026-06-15T07:00:00Z",
  endsAt: "2026-06-15T10:00:00Z"
})
model CreateAvailabilityWindowRequest {
  startsAt: UtcMinuteDateTime;
  endsAt: UtcMinuteDateTime;
}

@doc("Request to create a guest booking. The server computes endsAt from event type duration.")
@extension("x-example", #{
  eventTypeId: "22222222-2222-2222-2222-222222222222",
  startsAt: "2026-06-15T07:00:00Z",
  guestName: "Guest User",
  guestEmail: "guest@example.com"
})
model CreateBookingRequest {
  eventTypeId: ResourceId;

  @doc("Selected computed slot start in UTC.")
  startsAt: UtcMinuteDateTime;

  @minLength(1)
  @maxLength(120)
  guestName: string;

  @format("email")
  @minLength(1)
  @maxLength(254)
  guestEmail: string;
}

model EventTypeList {
  items: EventType[];
}

model AvailabilityWindowList {
  items: AvailabilityWindow[];
}

model SlotList {
  items: Slot[];
}

model BookingList {
  items: Booking[];
}

model CreatedEventTypeResponse {
  @statusCode statusCode: 201;
  @body body: EventType;
}

model CreatedAvailabilityWindowResponse {
  @statusCode statusCode: 201;
  @body body: AvailabilityWindow;
}

model CreatedBookingResponse {
  @statusCode statusCode: 201;
  @body body: Booking;
}

model NoContentResponse {
  @statusCode statusCode: 204;
}

model BadRequestResponse {
  @statusCode statusCode: 400;
  @body body: ProblemDetails;
}

model NotFoundResponse {
  @statusCode statusCode: 404;
  @body body: ProblemDetails;
}

model ConflictResponse {
  @statusCode statusCode: 409;
  @body body: ProblemDetails;
}

model UnprocessableEntityResponse {
  @statusCode statusCode: 422;
  @body body: ProblemDetails;
}

@tag("Public")
@route("/public")
interface PublicApi {
  @summary("Get public owner profile")
  @doc("Returns the single preconfigured owner, including IANA time zone for display.")
  @operationId("getPublicOwner")
  @extension("x-example", #{ response: #{ id: "11111111-1111-1111-1111-111111111111", displayName: "Alex Owner", timeZone: "Europe/Moscow" } })
  @get
  @route("/owner")
  getPublicOwner(): Owner;

  @summary("List public event types")
  @doc("Returns event types sorted by title ascending.")
  @operationId("listPublicEventTypes")
  @extension("x-example", #{ response: #{ items: #[#{ id: "22222222-2222-2222-2222-222222222222", title: "Intro call", description: "A short introductory call.", durationMinutes: 30 }] } })
  @get
  @route("/event-types")
  listPublicEventTypes(): EventTypeList;

  @summary("Get public event type")
  @operationId("getPublicEventType")
  @get
  @route("/event-types/{eventTypeId}")
  getPublicEventType(@path eventTypeId: ResourceId): EventType | NotFoundResponse;

  @summary("List free slots for an event type")
  @doc("Returns free slots in the strict booking window now < startsAt < now + 14 days, sorted by startsAt ascending.")
  @operationId("listPublicEventTypeSlots")
  @extension("x-example", #{ response: #{ items: #[#{ eventTypeId: "22222222-2222-2222-2222-222222222222", startsAt: "2026-06-15T07:00:00Z", endsAt: "2026-06-15T07:30:00Z", durationMinutes: 30 }] } })
  @get
  @route("/event-types/{eventTypeId}/slots")
  listPublicEventTypeSlots(@path eventTypeId: ResourceId): SlotList | NotFoundResponse;

  @summary("Create guest booking")
  @doc("Creates a booking for a computed free slot. The server computes endsAt from the event type duration.")
  @operationId("createPublicBooking")
  @extension("x-example", #{ request: #{ eventTypeId: "22222222-2222-2222-2222-222222222222", startsAt: "2026-06-15T07:00:00Z", guestName: "Guest User", guestEmail: "guest@example.com" } })
  @post
  @route("/bookings")
  createPublicBooking(@body request: CreateBookingRequest): CreatedBookingResponse | BadRequestResponse | NotFoundResponse | ConflictResponse | UnprocessableEntityResponse;
}

@tag("Owner")
@route("/owner")
interface OwnerApi {
  @summary("Get owner profile")
  @doc("Returns the single preconfigured owner. No authentication is required in the MVP.")
  @operationId("getOwner")
  @get
  getOwner(): Owner;

  @summary("List owner event types")
  @doc("Returns event types sorted by title ascending.")
  @operationId("listOwnerEventTypes")
  @get
  @route("/event-types")
  listOwnerEventTypes(): EventTypeList;

  @summary("Create owner event type")
  @doc("Creates an event type. Duplicate titles after trim and case-insensitive normalization return 409.")
  @operationId("createOwnerEventType")
  @post
  @route("/event-types")
  createOwnerEventType(@body request: CreateEventTypeRequest): CreatedEventTypeResponse | BadRequestResponse | ConflictResponse;

  @summary("List availability windows")
  @doc("Returns availability windows sorted by startsAt ascending.")
  @operationId("listOwnerAvailabilityWindows")
  @get
  @route("/availability-windows")
  listOwnerAvailabilityWindows(): AvailabilityWindowList;

  @summary("Create availability window")
  @doc("Creates a future UTC availability window. Overlap with another window returns 409; overlap with bookings is allowed.")
  @operationId("createOwnerAvailabilityWindow")
  @post
  @route("/availability-windows")
  createOwnerAvailabilityWindow(@body request: CreateAvailabilityWindowRequest): CreatedAvailabilityWindowResponse | BadRequestResponse | ConflictResponse;

  @summary("Delete availability window")
  @doc("Deletes an availability window. Existing bookings remain unchanged.")
  @operationId("deleteOwnerAvailabilityWindow")
  @delete
  @route("/availability-windows/{availabilityWindowId}")
  deleteOwnerAvailabilityWindow(@path availabilityWindowId: ResourceId): NoContentResponse | NotFoundResponse;

  @summary("List upcoming owner bookings")
  @doc("Returns scheduled bookings with startsAt > server now, sorted by startsAt ascending.")
  @operationId("listOwnerUpcomingBookings")
  @get
  @route("/bookings/upcoming")
  listOwnerUpcomingBookings(): BookingList;

  @summary("Cancel owner booking")
  @doc("Cancels a future scheduled booking. Repeated cancellation is idempotent and returns the cancelled booking.")
  @operationId("cancelOwnerBooking")
  @post
  @route("/bookings/{bookingId}/cancel")
  cancelOwnerBooking(@path bookingId: ResourceId): Booking | NotFoundResponse | UnprocessableEntityResponse;
}
