import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getInfo from '@salesforce/apex/IO_AppController.getInfo';
import listInbox from '@salesforce/apex/IO_AppController.listInbox';
import getInboxItemBody from '@salesforce/apex/IO_AppController.getInboxItemBody';
import replay from '@salesforce/apex/IO_AppController.replay';

import { API_VERSION, sfGetJson, safeJsonParse, pillClass, clamp, fmtDate } from 'c/ioUtil';

const METHOD_OPTIONS = [
    { label: 'POST', value: 'POST' },
    { label: 'PUT', value: 'PUT' },
    { label: 'PATCH', value: 'PATCH' },
    { label: 'DELETE', value: 'DELETE' }
];

export default class IoApp extends LightningElement {
    @track info = { version: '0.0.0', apiVersion: API_VERSION, webhookPath: '/services/apexrest/io/webhook' };

    activeTab = 'overview';

    busy = false;
    busyLabel = '';

    limits = null;
    limitsFetchedAt = '';
    apiHealthLabel = 'OK';
    apiHealthClass = 'pill pillOk';

    @track namedCreds = [];
    selectedNC = null;

    @track inbox = [];
    inboxFetchedAt = '';
    selectedItemId = null;
    selectedItemTitle = '';
    selectedItemJson = '';
    replayPath = '/';
    replayMethod = 'POST';
    replayResult = null;

    get baseUrl() {
        try { return window.location.origin; } catch { return ''; }
    }

    get methodOptions() { return METHOD_OPTIONS; }

    get tabClassOverview() { return this.tabClass('overview'); }
    get tabClassLimits() { return this.tabClass('limits'); }
    get tabClassCreds() { return this.tabClass('creds'); }
    get tabClassInbox() { return this.tabClass('inbox'); }
    get tabClassCorr() { return this.tabClass('corr'); }

    tabClass(name) {
        return name === this.activeTab ? 'tab tabActive' : 'tab';
    }

    get isOverview() { return this.activeTab === 'overview'; }
    get isLimits() { return this.activeTab === 'limits'; }
    get isCreds() { return this.activeTab === 'creds'; }
    get isInbox() { return this.activeTab === 'inbox'; }
    get isCorrelation() { return this.activeTab === 'corr'; }

    get inboxCount() { return (this.inbox || []).length; }

    get limitsPretty() {
        if (!this.limits) return '';
        try { return JSON.stringify(this.limits, null, 2); } catch { return String(this.limits); }
    }

    get limitBars() {
        const l = this.limits || {};
        const picks = [
            { key: 'DailyApiRequests', label: 'Daily API Requests' },
            { key: 'DailyAsyncApexExecutions', label: 'Daily Async Apex' },
            { key: 'DailyBulkApiRequests', label: 'Daily Bulk API' },
            { key: 'DailyStreamingApiEvents', label: 'Daily Streaming' }
        ];

        return picks
            .filter(p => l[p.key])
            .map(p => {
                const max = Number(l[p.key].Max) || 0;
                const rem = Number(l[p.key].Remaining) || 0;
                const used = Math.max(0, max - rem);
                const pct = max ? Math.round((used / max) * 100) : 0;

                const level = pct >= 90 ? 'high' : (pct >= 75 ? 'warn' : 'ok');
                const barClass = level === 'high' ? 'barFill barHigh' : (level === 'warn' ? 'barFill barWarn' : 'barFill');

                return {
                    key: p.key,
                    label: p.label,
                    used,
                    max,
                    pct,
                    barClass,
                    style: `width:${clamp(pct, 0, 100)}%`
                };
            });
    }

    get replayDisabled() {
        return this.busy || !this.selectedItemJson || !this.selectedNC || !this.replayPath;
    }

    connectedCallback() {
        this.init();
    }

    async init() {
        await this.withBusy('Loading...', async () => {
            this.info = await getInfo();
            await this.loadInbox();
            await this.loadLimits();
        });
    }

    async refreshAll() {
        await this.withBusy('Refreshing...', async () => {
            await this.loadInbox();
            await this.loadLimits();
            if (this.activeTab === 'creds') await this.loadNamedCreds();
        });
    }

    goOverview = () => { this.activeTab = 'overview'; };
    goLimits = () => { this.activeTab = 'limits'; };
    goCreds = () => { this.activeTab = 'creds'; };
    goInbox = () => { this.activeTab = 'inbox'; };
    goCorrelation = () => { this.activeTab = 'corr'; };

    async loadLimits() {
        try {
            const data = await sfGetJson(`/services/data/v${API_VERSION}/limits`);
            this.limits = data;
            this.limitsFetchedAt = new Date().toLocaleTimeString();

            const bars = this.limitBars;
            const worst = bars.reduce((m, b) => Math.max(m, b.pct), 0);
            const level = worst >= 90 ? 'high' : (worst >= 75 ? 'warn' : 'ok');
            this.apiHealthLabel = level === 'high' ? 'HIGH' : (level === 'warn' ? 'WARN' : 'OK');
            this.apiHealthClass = pillClass(this.apiHealthLabel === 'HIGH' ? 'high' : (this.apiHealthLabel === 'WARN' ? 'warn' : 'ok'));
        } catch (e) {
            this.toast('Limits error', this.humanError(e), 'error');
            this.limits = null;
        }
    }

    async loadNamedCreds() {
        await this.withBusy('Loading Named Credentials...', async () => {
            const q = [
                'SELECT Id, MasterLabel, DeveloperName, Endpoint, PrincipalType, LastModifiedDate',
                'FROM NamedCredential',
                'ORDER BY LastModifiedDate DESC',
                'LIMIT 200'
            ].join(' ');

            const data = await sfGetJson(`/services/data/v${API_VERSION}/tooling/query?q=${encodeURIComponent(q)}`);
            this.namedCreds = data.records || [];
            if (!this.namedCreds.length) {
                this.toast('No results', 'No Named Credentials returned (or access is restricted).', 'warning');
            }
        });
    }

    selectNamedCredential(e) {
        const dev = e.currentTarget.dataset.devname;
        this.selectedNC = dev;
        this.toast('Selected', `Replay will use Named Credential: ${dev}`, 'success');
    }

    async loadInbox() {
        const items = await listInbox({ limitSize: 50 });
        this.inbox = (items || []).map(i => ({
            ...i,
            createdAt: fmtDate(i.createdAt)
        }));
        this.inboxFetchedAt = new Date().toLocaleTimeString();
    }

    async openInboxItem(e) {
        const id = e.currentTarget.dataset.id;
        this.selectedItemId = id;
        this.replayResult = null;

        await this.withBusy('Loading inbox item...', async () => {
            const b = await getInboxItemBody({ contentVersionId: id });
            this.selectedItemTitle = b.title;

            const obj = safeJsonParse(b.json);
            this.selectedItemJson = obj ? JSON.stringify(obj, null, 2) : b.json;
        });
    }

    handleReplayPath(e) { this.replayPath = e.target.value; }
    handleReplayMethod(e) { this.replayMethod = e.detail.value; }

    async replayNow() {
        const raw = this.selectedItemJson || '';
        const obj = safeJsonParse(raw);
        const body = obj?.body ?? raw;
        const corrId = obj?.correlationId || this.extractCorrIdFromTitle(this.selectedItemTitle) || null;

        await this.withBusy('Replaying...', async () => {
            const res = await replay({
                req: {
                    namedCredential: this.selectedNC,
                    path: this.replayPath,
                    method: this.replayMethod,
                    body: (typeof body === 'string') ? body : JSON.stringify(body),
                    headers: { 'Content-Type': 'application/json' },
                    corrId
                }
            });
            this.replayResult = res;
            this.toast('Replayed', `HTTP ${res.statusCode} ${res.status}`, res.statusCode >= 200 && res.statusCode < 300 ? 'success' : 'warning');
        });
    }

    extractCorrIdFromTitle(title) {
        const t = String(title || '');
        const parts = t.split('_');
        return parts.length >= 3 ? parts[2] : null;
    }

    async withBusy(label, fn) {
        this.busy = true;
        this.busyLabel = label || 'Working...';
        try {
            return await fn();
        } finally {
            this.busy = false;
            this.busyLabel = '';
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    humanError(e) {
        try {
            if (e?.body?.message) return e.body.message;
            if (Array.isArray(e?.body) && e.body[0]?.message) return e.body[0].message;
            if (e?.message) return e.message;
            return JSON.stringify(e);
        } catch {
            return String(e);
        }
    }

    noop() {}
}
