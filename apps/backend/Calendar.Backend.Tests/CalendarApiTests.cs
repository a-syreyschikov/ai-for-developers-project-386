using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace Calendar.Backend.Tests;

public sealed class CalendarApiTests
{
  private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

  [Fact]
  public async Task PublicEndpointsReturnRussianSeedData()
  {
    await using var factory = new WebApplicationFactory<Program>();
    using var client = factory.CreateClient();

    var owner = await ReadJson<OwnerDto>(await client.GetAsync("/api/public/owner"));
    var eventTypes = await ReadJson<EventTypeListDto>(await client.GetAsync("/api/public/event-types"));

    Assert.Equal("Алексей Петров", owner.DisplayName);
    Assert.Equal("Europe/Moscow", owner.TimeZone);
    var eventType = Assert.Single(eventTypes.Items);
    Assert.Equal("Вводная встреча", eventType.Title);
    Assert.Equal("Короткая встреча для знакомства и обсуждения задачи.", eventType.Description);
    Assert.Equal(30, eventType.DurationMinutes);
  }

  [Fact]
  public async Task CreateBookingReturnsConflictWhenSelectedSlotIsAlreadyBooked()
  {
    await using var factory = new WebApplicationFactory<Program>();
    using var client = factory.CreateClient();

    var eventTypes = await ReadJson<EventTypeListDto>(await client.GetAsync("/api/public/event-types"));
    var eventType = Assert.Single(eventTypes.Items);
    var slots = await ReadJson<SlotListDto>(await client.GetAsync($"/api/public/event-types/{eventType.Id}/slots"));
    var slot = Assert.Single(slots.Items.Take(1));

    var firstRequest = new
    {
      eventTypeId = eventType.Id,
      startsAt = slot.StartsAt,
      guestName = "Иван Иванов",
      guestEmail = "ivan@example.com"
    };

    var createdResponse = await client.PostAsJsonAsync("/api/public/bookings", firstRequest, JsonOptions);
    Assert.Equal(HttpStatusCode.Created, createdResponse.StatusCode);

    var conflictRequest = new
    {
      eventTypeId = eventType.Id,
      startsAt = slot.StartsAt,
      guestName = "Ольга Смирнова",
      guestEmail = "olga@example.com"
    };

    var conflictResponse = await client.PostAsJsonAsync("/api/public/bookings", conflictRequest, JsonOptions);
    var problem = await ReadJson<ProblemDetailsDto>(conflictResponse);

    Assert.Equal(HttpStatusCode.Conflict, conflictResponse.StatusCode);
    Assert.Equal("SLOT_UNAVAILABLE", problem.Code);
    Assert.Equal("Слот уже занят", problem.Title);
    Assert.Contains("уже пересекается", problem.Detail);
  }

  private static async Task<T> ReadJson<T>(HttpResponseMessage response)
  {
    var content = await response.Content.ReadAsStringAsync();
    Assert.True(response.Content.Headers.ContentType?.MediaType == "application/json", content);
    return JsonSerializer.Deserialize<T>(content, JsonOptions) ?? throw new InvalidOperationException(content);
  }

  private sealed record OwnerDto(Guid Id, string DisplayName, string TimeZone);

  private sealed record EventTypeDto(Guid Id, string Title, string Description, int DurationMinutes);

  private sealed record EventTypeListDto(IReadOnlyList<EventTypeDto> Items);

  private sealed record SlotDto(Guid EventTypeId, DateTime StartsAt, DateTime EndsAt, int DurationMinutes);

  private sealed record SlotListDto(IReadOnlyList<SlotDto> Items);

  private sealed record ProblemDetailsDto(string Type, string Title, int Status, string? Detail, string Code);
}
