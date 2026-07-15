import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export function UserMenu() {
  const { session, user, profile, signOut } = useAuth()
  const navigate = useNavigate()
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  // Close the menu when clicking outside of it.
  useEffect(() => {
    if (!open) return
    function onClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onClick)
    return () => document.removeEventListener('mousedown', onClick)
  }, [open])

  // Logged out: a plain sign-in link.
  if (!session) {
    return (
      <Link to="/login" className="user-menu-signin">
        Sign in
      </Link>
    )
  }

  const label = profile?.full_name ?? user?.email ?? 'Account'

  async function handleSignOut() {
    setOpen(false)
    await signOut()
    navigate('/login')
  }

  return (
    <div className="user-menu" ref={ref}>
      <button
        type="button"
        className="user-menu-trigger secondary"
        onClick={() => setOpen((v) => !v)}
        aria-haspopup="menu"
        aria-expanded={open}
      >
        <span className="user-menu-name">{label}</span>
        <span className="user-menu-caret" aria-hidden="true">
          ▾
        </span>
      </button>

      {open && (
        <div className="user-menu-dropdown" role="menu">
          <div className="user-menu-info">
            <strong>{profile?.full_name ?? 'Account'}</strong>
            {user?.email && <span className="meta">{user.email}</span>}
            {profile && (
              <span className={`badge role-${profile.role}`}>{profile.role}</span>
            )}
          </div>
          <button type="button" className="user-menu-item" onClick={() => void handleSignOut()}>
            Sign out
          </button>
        </div>
      )}
    </div>
  )
}
