<script setup>
import { onMounted, ref } from 'vue'

const releases = ref([])
const loading = ref(true)
const error = ref('')

onMounted(async () => {
  try {
    const response = await fetch('https://api.github.com/repos/Lakmal98/killport/releases')
    if (!response.ok) throw new Error(`GitHub API returned ${response.status}`)
    releases.value = await response.json()
  } catch (cause) {
    error.value = 'Could not load releases. Visit GitHub Releases to download a package.'
  } finally {
    loading.value = false
  }
})
</script>

# Downloads

Download released `killport` packages from GitHub. Verify the version before installing.

<p v-if="loading">Loading available releases...</p>

<div v-else-if="error" class="download-error">
  <p>{{ error }}</p>
  <a href="https://github.com/Lakmal98/killport/releases">Open GitHub Releases</a>
</div>

<div v-else-if="releases.length" class="release-list">
  <section v-for="release in releases" :key="release.id" class="release-item">
    <h2>{{ release.name || release.tag_name }}</h2>
    <p class="release-meta">Published {{ new Date(release.published_at).toLocaleDateString() }}</p>
    <div v-if="release.assets.length" class="asset-list">
      <a v-for="asset in release.assets" :key="asset.id" :href="asset.browser_download_url" class="download-link">
        Download {{ asset.name }}
      </a>
    </div>
    <a v-else :href="release.html_url">View release on GitHub</a>
  </section>
</div>

<div v-else>
  <p>No published releases found.</p>
  <a href="https://github.com/Lakmal98/killport/releases">View GitHub Releases</a>
</div>

<style>
.release-list {
  display: grid;
  gap: 1rem;
}

.release-item {
  border: 1px solid var(--vp-c-divider);
  padding: 1rem 1.25rem;
}

.release-item h2 {
  margin: 0;
}

.release-meta {
  color: var(--vp-c-text-2);
  font-size: 0.9rem;
}

.asset-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.download-link {
  align-items: center;
  background: #3451b2;
  border: 1px solid #263d8f;
  color: #ffffff !important;
  display: inline-flex;
  font-weight: 600;
  gap: 0.4rem;
  min-height: 2.5rem;
  padding: 0.5rem 0.85rem;
}

.download-link:hover {
  background: #263d8f;
}

.download-link,
.download-link:hover {
  text-decoration: none;
}

.download-link:focus-visible {
  outline: 2px solid #3451b2;
  outline-offset: 2px;
}

.dark .download-link {
  background: #a8b1ff;
  border-color: #c5caff;
  color: #17181c !important;
}

.dark .download-link:hover {
  background: #c5caff;
}

.download-error {
  border-left: 4px solid var(--vp-c-danger-1);
  padding-left: 1rem;
}
</style>
