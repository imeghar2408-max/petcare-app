import { useEffect, useState } from 'react';
import { api } from '../api';
import StatusDot from '../components/StatusDot';

interface AdminComplaint {
  id: string;
  category: string;
  subject: string;
  description: string;
  status: 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED';
  adminNote: string | null;
  createdAt: string;
  reportedBy: { name: string; phone: string; role: string };
  booking: {
    id: string;
    serviceType: string;
    pet: { name: string };
    provider: { user: { name: string } } | null;
  } | null;
}

function statusKind(status: string): 'success' | 'danger' | 'warning' | 'neutral' {
  if (status === 'OPEN') return 'danger';
  if (status === 'IN_PROGRESS') return 'warning';
  return 'success'; // RESOLVED / CLOSED
}

const STATUS_OPTIONS = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];

export default function ComplaintsPage() {
  const [complaints, setComplaints] = useState<AdminComplaint[] | null>(null);
  const [filter, setFilter] = useState('ALL');
  const [selected, setSelected] = useState<AdminComplaint | null>(null);
  const [draftStatus, setDraftStatus] = useState('OPEN');
  const [draftNote, setDraftNote] = useState('');
  const [saving, setSaving] = useState(false);

  function load() {
    const query = filter === 'ALL' ? '' : `?status=${filter}`;
    api.get(`/admin/complaints${query}`).then(setComplaints);
  }

  useEffect(load, [filter]);

  function openDetail(c: AdminComplaint) {
    setSelected(c);
    setDraftStatus(c.status);
    setDraftNote(c.adminNote ?? '');
  }

  async function save() {
    if (!selected) return;
    setSaving(true);
    try {
      await api.post(`/admin/complaints/${selected.id}/status`, {
        status: draftStatus,
        adminNote: draftNote || undefined,
      });
      setSelected(null);
      load();
    } finally {
      setSaving(false);
    }
  }

  return (
    <>
      <div className="page-header">
        <h1>Complaints</h1>
        <p>Reports filed by pet owners and providers — resolving one notifies whoever filed it.</p>
      </div>

      <div style={{ marginBottom: 14 }}>
        <select value={filter} onChange={(e) => setFilter(e.target.value)} className="btn">
          <option value="ALL">All statuses</option>
          {STATUS_OPTIONS.map((s) => (
            <option key={s} value={s}>
              {s.replace('_', ' ')}
            </option>
          ))}
        </select>
      </div>

      <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start' }}>
        <div className="panel" style={{ flex: 1 }}>
          {complaints === null ? (
            <div className="empty-state">Loading…</div>
          ) : complaints.length === 0 ? (
            <div className="empty-state">Nothing here — good sign.</div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Subject</th>
                  <th>Category</th>
                  <th>Reported by</th>
                  <th>Status</th>
                  <th>Filed</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {complaints.map((c) => (
                  <tr key={c.id}>
                    <td>
                      {c.subject}
                      {c.booking && (
                        <div style={{ color: 'var(--ink-muted)', fontSize: 12, marginTop: 2 }}>
                          Re: {c.booking.serviceType.replace('_', ' ')} · {c.booking.pet.name}
                        </div>
                      )}
                    </td>
                    <td>{c.category.replace('_', ' ')}</td>
                    <td>
                      {c.reportedBy.name}
                      <div style={{ color: 'var(--ink-muted)', fontSize: 12 }}>{c.reportedBy.role}</div>
                    </td>
                    <td>
                      <StatusDot kind={statusKind(c.status)} label={c.status.replace('_', ' ')} />
                    </td>
                    <td>{new Date(c.createdAt).toLocaleDateString()}</td>
                    <td>
                      <button className="btn" onClick={() => openDetail(c)}>
                        Review
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {selected && (
          <div className="panel" style={{ width: 340, padding: 20, flexShrink: 0 }}>
            <h3 style={{ fontSize: 16, marginBottom: 4 }}>{selected.subject}</h3>
            <p style={{ color: 'var(--ink-muted)', fontSize: 12.5, marginTop: 0 }}>
              {selected.category.replace('_', ' ')} · filed by {selected.reportedBy.name} (
              {selected.reportedBy.role})
            </p>
            {selected.booking && (
              <p style={{ fontSize: 12.5, color: 'var(--ink-muted)' }}>
                Booking: {selected.booking.serviceType.replace('_', ' ')} for {selected.booking.pet.name}
                {selected.booking.provider && ` with ${selected.booking.provider.user.name}`}
              </p>
            )}
            <p style={{ fontSize: 13.5, lineHeight: 1.55 }}>{selected.description}</p>

            <div className="field">
              <label>Status</label>
              <select
                value={draftStatus}
                onChange={(e) => setDraftStatus(e.target.value)}
                style={{
                  width: '100%',
                  padding: '9px 11px',
                  border: '1px solid var(--line)',
                  borderRadius: 3,
                }}
              >
                {STATUS_OPTIONS.map((s) => (
                  <option key={s} value={s}>
                    {s.replace('_', ' ')}
                  </option>
                ))}
              </select>
            </div>

            <div className="field">
              <label>Internal note (sent to reporter if resolving/closing)</label>
              <textarea
                value={draftNote}
                onChange={(e) => setDraftNote(e.target.value)}
                rows={4}
                style={{
                  width: '100%',
                  padding: '9px 11px',
                  border: '1px solid var(--line)',
                  borderRadius: 3,
                  fontFamily: 'var(--sans)',
                  fontSize: 13.5,
                }}
              />
            </div>

            <div style={{ display: 'flex', gap: 8 }}>
              <button className="btn" onClick={() => setSelected(null)}>
                Cancel
              </button>
              <button className="btn btn-primary" onClick={save} disabled={saving}>
                {saving ? 'Saving…' : 'Save'}
              </button>
            </div>
          </div>
        )}
      </div>
    </>
  );
}
