<template>
  <section class="home-page">
    <div class="hero-copy">
      <span class="eyebrow">Запись без лишних шагов</span>
      <h1>Выберите встречу, свободное время и оставьте бронирование.</h1>
      <p>
        Calendar помогает владельцу опубликовать типы встреч и недельное расписание, а гостям — быстро записаться на свободный слот.
      </p>
      <div class="hero-actions">
        <Button label="Записаться" icon="pi pi-arrow-right" icon-pos="right" as="router-link" to="/book" />
        <Button label="Открыть админку" severity="secondary" outlined as="router-link" to="/admin" />
      </div>
    </div>

    <div class="hero-panel surface-card">
      <div class="metric-card">
        <span>01</span>
        <strong>Тип события</strong>
        <p>Гость выбирает формат и длительность встречи.</p>
      </div>
      <div class="metric-card accent">
        <span>02</span>
        <strong>Свободный слот</strong>
        <p>Frontend показывает только слоты, возвращённые backend по контракту.</p>
      </div>
      <div class="metric-card">
        <span>03</span>
        <strong>Бронирование</strong>
        <p>Backend сохраняет запись и блокирует пересекающиеся будущие встречи.</p>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import Button from 'primevue/button'
</script>

<style scoped>
.home-page {
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(320px, 0.9fr);
  gap: 28px;
  align-items: start;
  padding: 22px 0 36px;
}

.hero-copy {
  display: grid;
  gap: 18px;
}

.eyebrow {
  width: fit-content;
  border-radius: 999px;
  padding: 7px 12px;
  color: var(--brand);
  background: var(--brand-soft);
  font-weight: 800;
}

h1 {
  color: var(--text-strong);
  font-size: clamp(2.2rem, 4.6vw, 4rem);
  font-weight: 900;
  letter-spacing: -0.05em;
  line-height: 1.02;
}

p {
  color: var(--text-muted);
  font-size: 1rem;
  max-width: 620px;
}

.hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

.hero-panel {
  display: grid;
  gap: 12px;
  padding: 16px;
}

.metric-card {
  display: grid;
  gap: 8px;
  min-height: 124px;
  border-radius: 18px;
  padding: 18px;
  background: #f8fafc;
}

.metric-card.accent {
  color: #ffffff;
  background: linear-gradient(135deg, var(--brand), #7c3aed);
}

.metric-card span {
  color: var(--accent);
  font-weight: 900;
}

.metric-card.accent span,
.metric-card.accent p {
  color: rgba(255, 255, 255, 0.8);
}

.metric-card strong {
  color: inherit;
  font-size: 1.18rem;
  font-weight: 900;
}

.metric-card p {
  color: var(--text-muted);
  font-size: 0.95rem;
}

@media (max-width: 860px) {
  .home-page {
    grid-template-columns: 1fr;
  }
}
</style>
