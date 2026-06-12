<template>
  <section class="page-stack">
    <div class="page-heading">
      <h1>Предстоящие встречи</h1>
      <p>Будущие scheduled бронирования владельца. Отменённые встречи не показываются.</p>
    </div>

    <Message v-if="error" severity="error">{{ error }}</Message>

    <div v-if="loading" class="booking-list">
      <Skeleton v-for="item in 3" :key="item" height="8rem" border-radius="24px" />
    </div>

    <div v-else-if="bookings.length === 0" class="empty-state surface-card">
      <i class="pi pi-calendar-times" />
      <strong>Предстоящих встреч нет</strong>
      <span>Когда гость создаст бронирование, оно появится здесь.</span>
    </div>

    <div v-else class="booking-list">
      <article v-for="booking in bookings" :key="booking.id" class="booking-card surface-card">
        <div class="date-block">
          <strong>{{ owner ? formatDate(booking.startsAt, owner.timeZone) : booking.startsAt }}</strong>
          <span>{{ owner ? formatSlotRange(booking, owner.timeZone) : '' }}</span>
        </div>
        <div class="booking-info">
          <h2>{{ booking.eventTypeTitle }}</h2>
          <p v-if="owner">{{ owner.displayName }} и {{ booking.guestName }} · {{ booking.guestEmail }}</p>
          <Tag :value="`${booking.durationMinutes} минут`" severity="info" />
        </div>
        <Button label="Отменить" severity="danger" outlined @click="confirmCancel(booking)" />
      </article>
    </div>
  </section>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import Button from 'primevue/button'
import Message from 'primevue/message'
import Skeleton from 'primevue/skeleton'
import Tag from 'primevue/tag'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import { useI18n } from 'vue-i18n'
import { calendarApi, type Booking, type Owner } from '@/api/calendar'
import { formatDate, formatSlotRange } from '@/shared/datetime'
import { getErrorMessage } from '@/shared/errors'

const { t } = useI18n()
const confirm = useConfirm()
const toast = useToast()
const owner = ref<Owner | null>(null)
const bookings = ref<Booking[]>([])
const loading = ref(true)
const error = ref('')

const loadBookings = async () => {
  const [ownerResult, bookingsResult] = await Promise.all([
    calendarApi.getOwner(),
    calendarApi.listOwnerUpcomingBookings(),
  ])
  owner.value = ownerResult
  bookings.value = bookingsResult.items
}

const confirmCancel = (booking: Booking) => {
  confirm.require({
    header: 'Отменить встречу',
    message: `Отменить встречу «${booking.eventTypeTitle}»?`,
    acceptLabel: 'Отменить встречу',
    rejectLabel: 'Закрыть',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        await calendarApi.cancelOwnerBooking(booking.id)
        bookings.value = bookings.value.filter((item) => item.id !== booking.id)
        toast.add({ severity: 'success', summary: 'Встреча отменена', life: 3000 })
      } catch (caught) {
        toast.add({ severity: 'error', summary: 'Ошибка', detail: getErrorMessage(caught, t), life: 5000 })
      }
    },
  })
}

onMounted(async () => {
  try {
    await loadBookings()
  } catch (caught) {
    error.value = getErrorMessage(caught, t)
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.booking-list {
  display: grid;
  gap: 14px;
}

.booking-card {
  display: grid;
  grid-template-columns: 180px minmax(0, 1fr) auto;
  gap: 18px;
  align-items: center;
  padding: 18px;
}

.date-block {
  display: grid;
  border-radius: 20px;
  padding: 16px;
  background: var(--brand-soft);
}

.date-block strong,
.booking-info h2 {
  color: var(--text-strong);
  font-weight: 900;
}

.date-block span,
.booking-info p {
  color: var(--text-muted);
}

.booking-info {
  display: grid;
  gap: 6px;
}

.empty-state {
  display: grid;
  place-items: center;
  gap: 8px;
  padding: 48px 20px;
  text-align: center;
}

.empty-state i {
  color: var(--brand);
  font-size: 2rem;
}

.empty-state strong {
  color: var(--text-strong);
  font-size: 1.25rem;
  font-weight: 900;
}

@media (max-width: 760px) {
  .booking-card {
    grid-template-columns: 1fr;
  }
}
</style>
