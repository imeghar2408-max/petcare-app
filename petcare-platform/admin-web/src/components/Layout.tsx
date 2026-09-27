import { NavLink, Outlet } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from '../firebase';

export default function Layout() {
  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          PetCare
          <span>Operations</span>
        </div>
        <nav className="sidebar-nav">
          <NavLink to="/" end className={({ isActive }) => (isActive ? 'active' : '')}>
            Overview
          </NavLink>
          <NavLink to="/providers" className={({ isActive }) => (isActive ? 'active' : '')}>
            Provider verification
          </NavLink>
          <NavLink to="/bookings" className={({ isActive }) => (isActive ? 'active' : '')}>
            Bookings
          </NavLink>
          <NavLink to="/complaints" className={({ isActive }) => (isActive ? 'active' : '')}>
            Complaints
          </NavLink>
        </nav>
        <div className="sidebar-footer">
          {auth.currentUser?.email}
          <br />
          <button onClick={() => signOut(auth)}>Sign out</button>
        </div>
      </aside>
      <main className="main">
        <Outlet />
      </main>
    </div>
  );
}
