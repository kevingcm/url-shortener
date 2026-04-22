const form = document.getElementById('shorten-form');
const input = document.getElementById('url-input');
const result = document.getElementById('result');
const link = document.getElementById('short-link');
const copyBtn = document.getElementById('copy-btn');
const errorBox = document.getElementById('error');
const statsLink = document.getElementById('stats-link');

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  errorBox.classList.add('hidden');
  result.classList.add('hidden');

  try {
    const response = await fetch('/api/shorten', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ url: input.value }),
    });

    const data = await response.json();

    if (!response.ok) {
      errorBox.textContent = data.error || 'Something went wrong';
      errorBox.classList.remove('hidden');
      return;
    }

    link.href = data.short_url;
    link.textContent = data.short_url;
    statsLink.href = `/stats.html?code=${encodeURIComponent(data.short_code)}`;
    result.classList.remove('hidden');
  } catch (err) {
    errorBox.textContent = 'Network error — is the server running?';
    errorBox.classList.remove('hidden');
  }
});

copyBtn.addEventListener('click', async () => {
  try {
    await navigator.clipboard.writeText(link.textContent);
    copyBtn.textContent = 'Copied!';
    setTimeout(() => (copyBtn.textContent = 'Copy'), 1500);
  } catch {
    copyBtn.textContent = 'Copy failed';
  }
});
