import { useEffect, useState } from 'react';
import { api } from '../api';
import StatusDot from '../components/StatusDot';

interface PendingProvider {
  id: string;
  bio: string | null;
  yearsExperience: number | null;
  idDocumentUrl: string | null;
  user: { name: string; phone: string; email: string | null };
  servicesOffered: { serviceType: string; priceInr: number }[];
}

export default function ProviderVerificationPage() {
  const [providers, setProviders] = useState<PendingProvider[] | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  function load() {
    api.get('/admin/providers/pending').then(setProviders);
  }

  useEffect(load, []);

  async function decide(id: string, approve: boolean) {
    setBusyId(id);
    try {
      await api.post(`/admin/providers/${id}/verify`, { approve });
      setProviders((prev) => prev?.filter((p) => p.id !== id) ?? null);
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <div className="page-header">
        <h1>Provider verification</h1>
        <p>New providers wait here until approved — they can't appear in search or receive bookings until then.</p>
      </div>

      <div className="panel">
        {providers === null ? (
          <div className="empty-state">Loading…</div>
        ) : providers.length === 0 ? (
          <div className="empty-state">Nothing waiting on review.</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Provider</th>
                <th>Contact</th>
                <th>Services</th>
                <th>Experience</th>
                <th>ID document</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {providers.map((p) => (
                <tr key={p.id}>
                  <td>
                    <strong>{p.user.name}</strong>
                    {p.bio && (
                      <div style={{ color: 'var(--ink-muted)', fontSize: 12.5, marginTop: 2 }}>{p.bio}</div>
                    )}
                  </td>
                  <td className="mono">
                    {p.user.phone}
                    <br />
                    {p.user.email ?? '—'}
                  </td>
                  <td>
                    {p.servicesOffered.length === 0
                      ? '—'
                      : p.servicesOffered.map((s) => `${s.serviceType} (₹${s.priceInr})`).join(', ')}
                  </td>
                  <td>{p.yearsExperience != null ? `${p.yearsExperience} yrs` : '—'}</td>
                  <td>
                    {p.idDocumentUrl ? (
                      <a href={p.idDocumentUrl} target="_blank" rel="noreferrer">
                        View
                      </a>
                    ) : (
                      <StatusDot kind="warning" label="Not uploaded" />
                    )}
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: 8 }}>
                      <button
                        className="btn btn-danger"
                        disabled={busyId === p.id}
                        onClick={() => decide(p.id, false)}
                      >
                        Reject
                      </button>
                      <button
                        className="btn btn-primary"
                        disabled={busyId === p.id}
                        onClick={() => decide(p.id, true)}
                      >
                        Approve
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </>
  );
}
