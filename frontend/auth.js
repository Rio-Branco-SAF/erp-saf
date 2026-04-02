// ============================================================
// ERP SAF — Utilitário de Autenticação (auth.js)
// Inclua ANTES de qualquer outro script em todas as páginas
// ============================================================
(function () {
  'use strict';

  const STORAGE_ACCESS  = 'erp_access';
  const STORAGE_REFRESH = 'erp_refresh';
  const STORAGE_USER    = 'erp_user';

  function getAccess()  { return localStorage.getItem(STORAGE_ACCESS); }
  function getRefresh() { return localStorage.getItem(STORAGE_REFRESH); }
  function getUser()    { try { return JSON.parse(localStorage.getItem(STORAGE_USER) || 'null'); } catch { return null; } }

  function saveTokens(access, refresh, user) {
    localStorage.setItem(STORAGE_ACCESS, access);
    if (refresh) localStorage.setItem(STORAGE_REFRESH, refresh);
    if (user)    localStorage.setItem(STORAGE_USER, JSON.stringify(user));
  }

  function clearAuth() {
    localStorage.removeItem(STORAGE_ACCESS);
    localStorage.removeItem(STORAGE_REFRESH);
    localStorage.removeItem(STORAGE_USER);
  }

  function decodeJWT(token) {
    try {
      const b64 = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
      return JSON.parse(atob(b64));
    } catch { return null; }
  }

  function accessExpired() {
    const tok = getAccess();
    if (!tok) return true;
    const payload = decodeJWT(tok);
    if (!payload || !payload.exp) return true;
    return payload.exp * 1000 < Date.now() + 30000;
  }

  async function refreshAccessToken() {
    const refresh = getRefresh();
    if (!refresh) return false;
    try {
      const api = (window.ERP_CONFIG || {}).API_URL || '';
      const r = await fetch(api + '/api/auth/refresh', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refresh_token: refresh })
      });
      if (!r.ok) { clearAuth(); return false; }
      const data = await r.json();
      saveTokens(data.access_token || data.token, data.refresh_token || null, null);
      return true;
    } catch { return false; }
  }

  async function authHeaders(extra) {
    if (accessExpired()) {
      const ok = await refreshAccessToken();
      if (!ok) { redirectLogin(); return null; }
    }
    return Object.assign({
      'Content-Type': 'application/json',
      Authorization: 'Bearer ' + getAccess()
    }, extra || {});
  }

  async function apiFetch(path, options) {
    const api = (window.ERP_CONFIG || {}).API_URL || '';
    const hdrs = await authHeaders();
    if (!hdrs) return null;
    let res = await fetch(api + path, Object.assign({}, options, { headers: hdrs }));
    if (res.status === 401) {
      const body = await res.json().catch(() => ({}));
      if (body.expired) {
        const ok = await refreshAccessToken();
        if (ok) {
          const hdrs2 = await authHeaders();
          res = await fetch(api + path, Object.assign({}, options, { headers: hdrs2 }));
        } else { redirectLogin(); return null; }
      }
    }
    return res;
  }

  function redirectLogin(msg) {
    clearAuth();
    const here = encodeURIComponent(location.pathname + location.search);
    location.href = '/login.html?next=' + here + (msg ? '&msg=' + encodeURIComponent(msg) : '');
  }

  async function login(email, senha) {
    const api = (window.ERP_CONFIG || {}).API_URL || '';
    const r = await fetch(api + '/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, senha })
    });
    const data = await r.json();
    if (!r.ok) throw new Error(data.error || 'Erro ao fazer login.');
    // Accept both 'access_token' (new) and 'token' (legacy) field names
    saveTokens(data.access_token || data.token, data.refresh_token, data.usuario);
    return data;
  }

  async function logout() {
    try {
      const hdrs = await authHeaders();
      if (hdrs) {
        const api = (window.ERP_CONFIG || {}).API_URL || '';
        await fetch(api + '/api/auth/logout', { method: 'POST', headers: hdrs });
      }
    } catch { /* silencioso */ }
    clearAuth();
    location.href = '/login.html';
  }

  function requireAuth() {
    if (!getAccess()) { redirectLogin(); return false; }
    return true;
  }

  function populateUserUI() {
    const user = getUser();
    if (!user) return;
    document.querySelectorAll('[data-user-nome]').forEach(el  => { el.textContent = user.nome   || ''; });
    document.querySelectorAll('[data-user-email]').forEach(el => { el.textContent = user.email  || ''; });
    document.querySelectorAll('[data-user-perfil]').forEach(el=> { el.textContent = user.perfil || ''; });
  }

  window.ERPAuth = {
    login, logout, requireAuth, authHeaders, apiFetch,
    getUser, getAccess, populateUserUI, redirectLogin,
  };

  document.addEventListener('DOMContentLoaded', () => {
    if (document.body && document.body.dataset.authRequired) { requireAuth(); }
    populateUserUI();
  });
})();
