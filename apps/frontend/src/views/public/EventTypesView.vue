<template>
  <section class="page-stack">
    <div class="page-heading">
      <h1>Записаться</h1>
      <p v-if="owner">Вы записываетесь к {{ owner.displayName }}. Время будет показано в часовом поясе {{ owner.timeZone }}.</p>
      <p v-else>Выберите тип события и перейдите к свободным слотам.</p>
    </div>

    <Message v-if="error" severity="error">{{ error }}</Message>

    <div v-if="loading" class="event-grid">
      <Skeleton v-for="item in 3" :key="item" height="10rem" border-radius="22px" />
    </div>

    <div v-else-if="eventTypes.length === 0" class="empty-state surface-card">
      <i class="pi pi-calendar-times" />
      <strong>Типы событий пока не созданы</strong>
      <span>Владелец сможет добавить их в админке.</span>
    </div>

    <div v-else class="event-grid">
      <Card v-for="eventType in eventTypes" :key="eventType.id" class="event-card">
        <template #title>{{ eventType.title }}</template>
        <template #subtitle>{{ eventType.durationMinutes }} минут</template>
        <template #content>
          <p>{{ eventType.description || 'Описание не указано.' }}</p>
        </template>
        <template #footer>
          <Button label="Выбрать" icon="pi pi-arrow-right" icon-pos="right" as="router-link" :to="`/book/${eventType.id}`" />
        </template>
      </Card>
    </div>
  </section>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import Button from 'primevue/button'
import Card from 'primevue/card'
import Message from 'primevue/message'
import Skeleton from 'primevue/skeleton'
import { useI18n } from 'vue-i18n'
import { calendarApi, type EventType, type Owner } from '@/api/calendar'
import { getErrorMessage } from '@/shared/errors'

const { t } = useI18n()
const owner = ref<Owner | null>(null)
const eventTypes = ref<EventType[]>([])
const loading = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    const [ownerResult, eventTypesResult] = await Promise.all([
      calendarApi.getPublicOwner(),
      calendarApi.listPublicEventTypes(),
    ])
    owner.value = ownerResult
    eventTypes.value = eventTypesResult.items
  } catch (caught) {
    error.value = getErrorMessage(caught, t)
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.event-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(100%, 260px), 340px));
  gap: 16px;
}

.event-card {
  border-radius: 22px;
  overflow: hidden;
}

.event-card p {
  min-height: 72px;
  color: var(--text-muted);
}

.empty-state {
  display: grid;
  place-items: center;
  gap: 8px;
  padding: 36px 18px;
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
</style>
