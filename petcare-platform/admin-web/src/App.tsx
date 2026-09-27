import { useEffect, useState } from 'react';
import { onAuthStateChanged, User } from 'firebase/auth';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { auth } from './firebase';
import LoginPage from './pages/LoginPage';
import Layout from './components/Layout';
import OverviewPage from './pages/OverviewPage';
import ProviderVerificationPage from './pages/ProviderVerificationPage';
import BookingsPage from './pages/BookingsPage';
import ComplaintsPage from './pages/ComplaintsPage';

export default function App() {
  const [user, setUser] = useState<User | null>(null);
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    return onAuthStateChanged(auth, (u) => {
      setUser(u);
      setChecked(true);
    });
  }, []);

  if (!checked) return null;
  if (!user) return <LoginPage />;

  // NOTE: signing in with Firebase only proves *who* someone is — the
  // backend's AdminOnlyGuard still checks their User.role === 'ADMIN' in
  // Postgres on every request, so an unapproved staff login here will get
  // 403s from every admin endpoint rather than seeing real data.
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<OverviewPage />} />
          <Route path="/providers" element={<ProviderVerificationPage />} />
          <Route path="/bookings" element={<BookingsPage />} />
          <Route path="/complaints" element={<ComplaintsPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
