import { useEffect, useState } from 'react';
import { api } from '../api';

interface Metrics {
  totalBookings: number;
  pendingVerifications: number;
  activeProviders: number;
  totalOwners: number;
  revenueInr: number;
  bookingsByStatus: Record<string, number>;
  openComplaints: number;
}

export default function OverviewPage() {
  const [metrics, setMetrics] = useState<Metrics | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api
      .get('/admin/metrics')
      .then(setMetrics)
      .catch((e) => setError(e.message));
  }, []);

  return (
    <>
      <div className="page-header">
        <h1>Overview</h1>
        <p>What's happening across the platform right now.</p>
      </div>

      {error && <p className="error-text">{error}</p>}

      {metrics && (
        <>
          <div className="metric-grid">
            <div className="metric-card">
              <div className="label">Total bookings</div>
              <div className="value">{metrics.totalBookings}</div>
            </div>
            <div className="metric-card">
              <div className="label">Revenue collected</div>
              <div className="value">₹{metrics.revenueInr.toLocaleString('en-IN')}</div>
            </div>
            <div className="metric-card">
              <div className="label">Verified providers</div>
              <div className="value">{metrics.activeProviders}</div>
            </div>
            <div className="metric-card">
              <div className="label">Pending verification</div>
              <div className="value">{metrics.pendingVerifications}</div>
            </div>
            <div className="metric-card">
              <div className="label">Open complaints</div>
              <div className="value">{metrics.openComplaints}</div>
            </div>
          </div>

          <div className="panel">
            <table>
              <thead>
                <tr>
                  <th>Booking status</th>
                  <th>Count</th>
                </tr>
              </thead>
              <tbody>
                {Object.entries(metrics.bookingsByStatus).map(([status, count]) => (
                  <tr key={status}>
                    <td>{status.replace('_', ' ')}</td>
                    <td className="mono">{count}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </>
  );
}
