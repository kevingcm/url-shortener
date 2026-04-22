const params = new URLSearchParams(window.location.search);
const code = params.get('code');

const errorBox = document.getElementById('error');
const content = document.getElementById('stats-content');
const title = document.getElementById('stats-title');
const subtitle = document.getElementById('stats-subtitle');
const totalClicks = document.getElementById('total-clicks');
const byDayBody = document.getElementById('by-day-body');
const referrersBody = document.getElementById('referrers-body');

async function loadStats() {
  if (!code) {
    errorBox.textContent = 'No short code provided. Try /stats.html?code=abc123';
    errorBox.classList.remove('hidden');
    return;
  }

  try {
    const response = await fetch(`/api/stats/${encodeURIComponent(code)}`);
    const data = await response.json();

    if (!response.ok) {
      errorBox.textContent = data.error || 'Failed to load stats';
      errorBox.classList.remove('hidden');
      return;
    }

    title.textContent = `/${data.short_code}`;
    subtitle.innerHTML = `→ <a href="${data.long_url}" target="_blank" rel="noopener">${data.long_url}</a>`;
    totalClicks.textContent = data.total_clicks;

    byDayBody.innerHTML = data.clicks_by_day.length
      ? data.clicks_by_day.map(r => `<tr><td>${r.day}</td><td>${r.count}</td></tr>`).join('')
      : '<tr><td colspan="2" class="empty">No clicks yet</td></tr>';

    referrersBody.innerHTML = data.top_referrers.length
      ? data.top_referrers.map(r => `<tr><td>${escapeHtml(r.referrer)}</td><td>${r.count}</td></tr>`).join('')
      : '<tr><td colspan="2" class="empty">No clicks yet</td></tr>';

    content.classList.remove('hidden');
  } catch {
    errorBox.textContent = 'Network error — is the server running?';
    errorBox.classList.remove('hidden');
  }
}

function escapeHtml(s) {
  return String(s)
    .replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;').replaceAll("'", '&#39;');
}

loadStats();
