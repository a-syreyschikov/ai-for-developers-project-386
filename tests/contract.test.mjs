import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import YAML from "yaml";

const openapi = YAML.parse(await readFile(new URL("../contracts/openapi.yaml", import.meta.url), "utf8"));

const requiredPaths = {
  "/api/public/owner": ["get"],
  "/api/public/event-types": ["get"],
  "/api/public/event-types/{eventTypeId}": ["get"],
  "/api/public/event-types/{eventTypeId}/slots": ["get"],
  "/api/public/bookings": ["post"],
  "/api/owner": ["get"],
  "/api/owner/event-types": ["get", "post"],
  "/api/owner/availability-windows": ["get", "post"],
  "/api/owner/availability-windows/{availabilityWindowId}": ["delete"],
  "/api/owner/bookings/upcoming": ["get"],
  "/api/owner/bookings/{bookingId}/cancel": ["post"],
};

const operationIds = [
  "getPublicOwner",
  "listPublicEventTypes",
  "getPublicEventType",
  "listPublicEventTypeSlots",
  "createPublicBooking",
  "getOwner",
  "listOwnerEventTypes",
  "createOwnerEventType",
  "listOwnerAvailabilityWindows",
  "createOwnerAvailabilityWindow",
  "deleteOwnerAvailabilityWindow",
  "listOwnerUpcomingBookings",
  "cancelOwnerBooking",
];

const schemas = () => openapi.components.schemas;

function operation(path, method) {
  return openapi.paths[path]?.[method];
}

function schema(name) {
  return schemas()[name];
}

function schemaProperties(name) {
  return schema(name)?.properties ?? {};
}

function responseCodes(path, method) {
  return Object.keys(operation(path, method)?.responses ?? {});
}

function hasSchemaExample(name) {
  const component = schema(name);
  return Boolean(component?.example ?? component?.["x-example"] ?? component?.examples);
}

test("OpenAPI document has expected metadata", () => {
  assert.equal(openapi.openapi, "3.0.0");
  assert.equal(openapi.info.title, "Calendar API");
  assert.equal(openapi.info.version, "0.1.0");
  assert.equal(openapi.servers[0].url, "http://localhost:8080");
  assert.equal(openapi.servers[0].description, "Local development server");
});

test("OpenAPI document exposes all owner and public paths", () => {
  for (const [path, methods] of Object.entries(requiredPaths)) {
    assert.ok(openapi.paths[path], `missing path ${path}`);
    for (const method of methods) {
      assert.ok(operation(path, method), `missing ${method.toUpperCase()} ${path}`);
    }
  }
});

test("operations have stable operationIds and tags", () => {
  const seenOperationIds = [];

  for (const [path, methods] of Object.entries(requiredPaths)) {
    for (const method of methods) {
      const op = operation(path, method);
      seenOperationIds.push(op.operationId);
      assert.ok(op.tags?.includes(path.includes("/api/public") ? "Public" : "Owner"), `missing tag for ${method} ${path}`);
    }
  }

  assert.deepEqual(seenOperationIds.toSorted(), operationIds.toSorted());
});

test("domain schemas contain required fields", () => {
  for (const name of ["Owner", "EventType", "AvailabilityWindow", "Slot", "Booking", "ProblemDetails"]) {
    assert.ok(schema(name), `missing schema ${name}`);
  }

  assert.deepEqual(schema("Owner").required.toSorted(), ["displayName", "id", "timeZone"].toSorted());
  assert.deepEqual(schema("EventType").required.toSorted(), ["description", "durationMinutes", "id", "title"].toSorted());
  assert.deepEqual(schema("AvailabilityWindow").required.toSorted(), ["endsAt", "id", "startsAt"].toSorted());
  assert.deepEqual(schema("Slot").required.toSorted(), ["durationMinutes", "endsAt", "eventTypeId", "startsAt"].toSorted());
  assert.deepEqual(schema("Booking").required.toSorted(), [
    "createdAt",
    "durationMinutes",
    "endsAt",
    "eventTypeId",
    "eventTypeTitle",
    "guestEmail",
    "guestName",
    "id",
    "startsAt",
    "status",
  ].toSorted());
});

test("schemas encode agreed validation constraints", () => {
  assert.equal(schema("ResourceId").format, "uuid");
  assert.equal(schemaProperties("Owner").displayName.minLength, 1);
  assert.equal(schemaProperties("Owner").displayName.maxLength, 120);

  assert.equal(schemaProperties("EventType").title.minLength, 1);
  assert.equal(schemaProperties("EventType").title.maxLength, 120);
  assert.equal(schemaProperties("EventType").description.maxLength, 1000);
  assert.equal(schemaProperties("EventType").durationMinutes.minimum, 15);
  assert.equal(schemaProperties("EventType").durationMinutes.maximum, 240);
  assert.equal(schemaProperties("EventType").durationMinutes.multipleOf, 15);

  assert.equal(schemaProperties("Booking").guestEmail.format, "email");
  assert.equal(schemaProperties("Booking").guestEmail.maxLength, 254);
  assert.deepEqual(schema("BookingStatus").enum.toSorted(), ["cancelled", "scheduled"]);
});

test("list responses use the items wrapper", () => {
  for (const name of ["EventTypeList", "AvailabilityWindowList", "SlotList", "BookingList"]) {
    assert.deepEqual(schema(name).required, ["items"]);
    assert.equal(schemaProperties(name).items.type, "array");
  }
});

test("error responses and error codes cover MVP scenarios", () => {
  assert.deepEqual(schema("ErrorCode").enum.toSorted(), [
    "AVAILABILITY_WINDOW_NOT_FOUND",
    "AVAILABILITY_WINDOW_OVERLAP",
    "BOOKING_NOT_CANCELLABLE",
    "BOOKING_NOT_FOUND",
    "DUPLICATE_EVENT_TYPE_TITLE",
    "EVENT_TYPE_NOT_FOUND",
    "SLOT_OUTSIDE_BOOKING_WINDOW",
    "SLOT_UNAVAILABLE",
    "VALIDATION_FAILED",
  ].toSorted());

  assert.ok(responseCodes("/api/public/bookings", "post").includes("400"));
  assert.ok(responseCodes("/api/public/bookings", "post").includes("404"));
  assert.ok(responseCodes("/api/public/bookings", "post").includes("409"));
  assert.ok(responseCodes("/api/public/bookings", "post").includes("422"));
  assert.ok(responseCodes("/api/owner/event-types", "post").includes("409"));
  assert.ok(responseCodes("/api/owner/availability-windows", "post").includes("409"));
  assert.ok(responseCodes("/api/owner/bookings/{bookingId}/cancel", "post").includes("422"));
});

test("create and delete operations use agreed status codes", () => {
  assert.ok(responseCodes("/api/owner/event-types", "post").includes("201"));
  assert.ok(responseCodes("/api/owner/availability-windows", "post").includes("201"));
  assert.ok(responseCodes("/api/public/bookings", "post").includes("201"));
  assert.ok(responseCodes("/api/owner/availability-windows/{availabilityWindowId}", "delete").includes("204"));
});

test("schemas include smoke examples for implementation agents", () => {
  for (const name of ["Owner", "EventType", "AvailabilityWindow", "Slot", "Booking", "CreateBookingRequest", "ProblemDetails"]) {
    assert.ok(hasSchemaExample(name), `missing schema example for ${name}`);
  }
});
