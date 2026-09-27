import { useEffect, useState } from 'react';
import { api } from '../api';
import StatusDot from '../components/StatusDot';

interface AdminBooking {
  id: string;
  serviceType: string;
  status: string;
  scheduledAt: string;
  priceInr: number;
  pet: { name: string };
  petOwner: { user: { name: string } };
  provider: { user: { name: string } } | null;
  payment: { status: string } | null;
}

function statusKind(status: string): 'success' | 'danger' | 'warning' | 'neutral' {
  if (status === 'COMPLETED') return 'success';
  if (status === 'REJECTED' || status === 'CANCELLED') return 'danger';
  if (status === 'REQUESTED') return 'warning';
  return 'neutral';
}

export default function BookingsPage() {
  const [bookings, setBookings] = useState<AdminBooking[] | null>(null);
  const [filter, setFilter] = useState('ALL');

  useEffect(() => {
    api.get('/admin/bookings').then(setBookings);
  }, []);

  const filtered = bookings?.filter((b) => filter === 'ALL' || b.status === filter);

  return (
    <>
      <div className="page-header">
        <h1>Bookings</h1>
        <p>Most recent 100 bookings across the platform, for support lookups.</p>
      </div>

      <div style={{ marginBottom: 14 }}>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="btn"
          style={{ fontFamily: 'var(--sans)' }}
        >
          <option value="ALL">All statuses</option>
          <option value="REQUESTED">Requested</option>
          <option value="ACCEPTED">Accepted</option>
          <option value="IN_PROGRESS">In progress</option>
          <option value="COMPLETED">Completed</option>
          <option value="REJECTED">Rejected</option>
          <option value="CANCELLED">Cancelled</option>
        </select>
      </div>

      <div className="panel">
        {filtered === null || filtered === undefined ? (
          <div className="empty-state">Loading…</div>
        ) : filtered.length === 0 ? (
          <div className="empty-state">No bookings match this filter.</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Booking</th>
                <th>Owner</th>
                <th>Provider</th>
                <th>Scheduled</th>
                <th>Status</th>
                <th>Payment</th>
                <th>Amount</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((b) => (
                <tr key={b.id}>
                  <td>
                    {b.serviceType.replace('_', ' ')} · {b.pet.name}
                    <div className="mono" style={{ color: 'var(--ink-faint)', fontSize: 11 }}>
                      {b.id}
                    </div>
                  </td>
                  <td>{b.petOwner.user.name}</td>
                  <td>{b.provider?.user.name ?? '—'}</td>
                  <td>{new Date(b.scheduledAt).toLocaleString()}</td>
                  <td>
                    <StatusDot kind={statusKind(b.status)} label={b.status.replace('_', ' ')} />
                  </td>
                  <td>{b.payment?.status ?? '—'}</td>
                  <td className="mono">₹{b.priceInr}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </>
  );
}
