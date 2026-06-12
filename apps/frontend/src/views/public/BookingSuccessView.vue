<template>
  <section class="success-page surface-card">
    <i class="pi pi-check-circle" />
    <template v-if="booking && owner">
      <h1>Запись создана</h1>
      <p>Мы сохранили бронирование. Сохраните дату и время встречи.</p>
      <dl>
        <div><dt>Владелец</dt><dd>{{ owner.displayName }}</dd></div>
        <div><dt>Гость</dt><dd>{{ booking.guestName }} · {{ booking.guestEmail }}</dd></div>
        <div><dt>Событие</dt><dd>{{ booking.eventTypeTitle }}</dd></div>
        <div><dt>Дата и время</dt><dd>{{ formatDate(booking.startsAt, owner.timeZone) }} · {{ formatSlotRange(booking, owner.timeZone) }}</dd></div>
        <div><dt>Продолжительность</dt><dd>{{ booking.durationMinutes }} минут</dd></div>
      </dl>
    </template>
    <template v-else>
      <h1>Запись создана</h1>
      <p>Данные записи недоступны после обновления страницы, но бронирование могло быть успешно сохранено.</p>
    </template>
    <div class="actions">
      <Button label="На главную" as="router-link" to="/" />
      <Button label="Записаться ещё" severity="secondary" outlined as="router-link" to="/book" />
    </div>
  </section>
</template>

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import Button from 'primevue/button'
import { useBookingStore } from '@/stores/booking'
import { formatDate, formatSlotRange } from '@/shared/datetime'

const bookingStore = useBookingStore()
const { createdBooking: booking, owner } = storeToRefs(bookingStore)
</script>

<style scoped>
.success-page {
  display: grid;
  justify-items: center;
  gap: 18px;
  max-width: 760px;
  margin: 40px auto;
  padding: 40px;
  text-align: center;
}

.success-page > i {
  color: #16a34a;
  font-size: 3.5rem;
}

h1 {
  color: var(--text-strong);
  font-size: clamp(2rem, 5vw, 3.4rem);
  font-weight: 900;
  letter-spacing: -0.05em;
  line-height: 1;
}

p {
  color: var(--text-muted);
}

dl {
  display: grid;
  gap: 10px;
  width: 100%;
  text-align: left;
}

dl div {
  display: grid;
  grid-template-columns: 160px 1fr;
  gap: 16px;
  padding: 12px 0;
  border-top: 1px solid var(--surface-border);
}

dt {
  color: var(--text-muted);
}

dd {
  color: var(--text-strong);
  font-weight: 800;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 12px;
}

@media (max-width: 640px) {
  dl div {
    grid-template-columns: 1fr;
    gap: 4px;
  }
}
</style>
