// =====================================================
//  Mirai Atelier — Shared Utilities
// =====================================================

const ROLES = {
  produser:    { label: 'Produser',    icon: '🎭', color: '#c084fc' },
  director:    { label: 'Director',    icon: '🎬', color: '#60a5fa' },
  modeller:    { label: 'Modeller',    icon: '🎨', color: '#34d399' },
  programmer:  { label: 'Programmer',  icon: '💻', color: '#fb923c' },
  animator:    { label: 'Animator',    icon: '✨', color: '#f472b6' },
  ui_designer: { label: 'UI Designer', icon: '🖌️', color: '#22d3ee' },
  admin:       { label: 'Admin',       icon: '👑', color: '#e8b84b' }
};

const STATUS_MAP = {
  ongoing:   { label: 'ON GOING',  dot: '#4ade80' },
  on_review: { label: 'ON REVIEW', dot: '#fbbf24' },
  processed: { label: 'PROCESSED', dot: '#e8b84b' },
  revision:  { label: 'REVISION',  dot: '#f87171' }
};

const PRIORITY_MAP = {
  low:    'Low',
  medium: 'Medium',
  high:   'High',
  urgent: 'Urgent'
};

// ── Auth helpers ──────────────────────────────────────

async function getSession() {
  const { data: { session } } = await db.auth.getSession();
  return session;
}

async function getProfile(uid) {
  const { data } = await db.from('profiles').select('*').eq('id', uid).single();
  return data;
}

async function requireAuth(redirect = '/login') {
  const session = await getSession();
  if (!session) { window.location.href = redirect; return null; }
  return session;
}

async function requireAdmin(redirect = '/dashboard') {
  const session = await requireAuth();
  if (!session) return null;
  const profile = await getProfile(session.user.id);
  if (!profile || profile.role !== 'admin') { window.location.href = redirect; return null; }
  return { session, profile };
}

async function signOut() {
  await db.auth.signOut();
  window.location.href = '/login';
}

// ── UI helpers ────────────────────────────────────────

function roleBadge(role) {
  const r = ROLES[role];
  if (!r) return `<span class="badge">${role}</span>`;
  return `<span class="badge badge-${role}">${r.icon} ${r.label}</span>`;
}

function statusBadge(status) {
  return `<span class="badge badge-${status}">${STATUS_MAP[status]?.label || status}</span>`;
}

function priorityBadge(priority) {
  return `<span class="badge badge-${priority}">${PRIORITY_MAP[priority] || priority}</span>`;
}

function initials(name = '') {
  return name.split(' ').slice(0, 2).map(n => n[0] || '').join('').toUpperCase() || '??';
}

function formatDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
}

function timeAgo(d) {
  if (!d) return '';
  const diff = Date.now() - new Date(d).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 1)  return 'baru saja';
  if (m < 60) return `${m}m lalu`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}j lalu`;
  return `${Math.floor(h / 24)}h lalu`;
}

function isOverdue(due) {
  if (!due) return false;
  return new Date(due) < new Date();
}

function showToast(msg, type = 'info') {
  document.querySelectorAll('.toast').forEach(t => t.remove());
  const el = document.createElement('div');
  el.className = `toast toast-${type}`;
  el.textContent = msg;
  document.body.appendChild(el);
  requestAnimationFrame(() => el.classList.add('show'));
  setTimeout(() => { el.classList.remove('show'); setTimeout(() => el.remove(), 300); }, 3500);
}

function setLoading(btn, on, text = '') {
  if (on) {
    btn._orig = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = `<span class="spinner"></span> ${text || 'Loading...'}`;
  } else {
    btn.disabled = false;
    btn.innerHTML = btn._orig || text;
  }
}

function openModal(id) { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }

// Close modal on backdrop click
document.addEventListener('click', e => {
  if (e.target.classList.contains('modal-overlay')) {
    e.target.classList.remove('open');
  }
});
