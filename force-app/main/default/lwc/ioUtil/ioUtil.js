export const API_VERSION = '55.0';

export function fmtDate(dt) {
    if (!dt) return '';
    try { return new Date(dt).toLocaleString(); } catch { return String(dt); }
}

export function clamp(n, min, max) {
    const x = Number(n) || 0;
    return Math.max(min, Math.min(max, x));
}

export async function sfGetJson(url) {
    const res = await fetch(url, { method: 'GET', headers: { 'Content-Type': 'application/json' }});
    if (!res.ok) {
        const t = await res.text();
        throw new Error(`HTTP ${res.status} ${res.statusText}: ${t}`);
    }
    return res.json();
}

export function safeJsonParse(text) {
    try { return JSON.parse(text); } catch { return null; }
}

export function pillClass(level) {
    const v = String(level || '').toLowerCase();
    if (v === 'high') return 'pill pillHigh';
    if (v === 'warn') return 'pill pillWarn';
    return 'pill pillOk';
}
