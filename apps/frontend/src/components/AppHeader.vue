<template>
  <header class="app-header">
    <RouterLink class="brand" to="/" aria-label="Calendar">
      <span class="brand-mark"><i class="pi pi-calendar" /></span>
      <span>{{ t('app.name') }}</span>
    </RouterLink>

    <nav class="main-nav" aria-label="Главная навигация">
      <RouterLink to="/book">{{ t('app.nav.book') }}</RouterLink>
      <RouterLink to="/admin">{{ t('app.nav.admin') }}</RouterLink>
    </nav>
  </header>
</template>

<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>

<style scoped>
.app-header {
  position: sticky;
  top: 0;
  z-index: 20;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  width: min(1180px, calc(100% - 28px));
  margin: 12px auto 0;
  padding: 10px 14px;
  border: 1px solid var(--surface-border);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.86);
  box-shadow: 0 16px 44px rgba(15, 23, 42, 0.07);
  backdrop-filter: blur(18px);
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  color: var(--text-strong);
  font-size: 1.05rem;
  font-weight: 800;
}

.brand-mark {
  display: grid;
  width: 36px;
  height: 36px;
  place-items: center;
  border-radius: 50%;
  color: #ffffff;
  background: linear-gradient(135deg, var(--brand), #7c3aed);
}

.main-nav {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.main-nav a {
  border-radius: 999px;
  color: var(--text-muted);
  font-weight: 700;
  padding: 8px 12px;
}

.main-nav a.router-link-active {
  color: var(--brand);
  background: var(--brand-soft);
}

@media (max-width: 560px) {
  .app-header {
    align-items: flex-start;
    border-radius: 22px;
    flex-direction: column;
  }

  .main-nav {
    width: 100%;
  }

  .main-nav a {
    flex: 1;
    text-align: center;
  }
}
</style>
