import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { supabase, type Project } from '../lib/supabase'

export function Dashboard() {
  const { profile, user } = useAuth()
  const [projects, setProjects] = useState<Project[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let active = true
    ;(async () => {
      const { data, error } = await supabase
        .from('projects')
        // RLS transparently limits this to projects the user may see.
        .select('*')
        .order('created_at', { ascending: true })
      if (!active) return
      if (error) setError(error.message)
      else setProjects(data ?? [])
      setLoading(false)
    })()
    return () => {
      active = false
    }
  }, [])

  return (
    <>
      <header className="topbar">
        <div>
          <h1>Projects</h1>
          <p className="muted">
            {profile?.full_name ?? user?.email}
            {profile && <span className={`badge role-${profile.role}`}>{profile.role}</span>}
          </p>
        </div>
      </header>

      {loading && <p>Loading projects…</p>}
      {error && <p className="error">{error}</p>}
      {!loading && !error && projects.length === 0 && (
        <p className="muted">No projects are available to you yet.</p>
      )}

      <ul className="cards">
        {projects.map((p) => (
          <li key={p.id} className="card">
            <Link to={`/projects/${p.id}`}>
              <div className="card-head">
                <h2>{p.name}</h2>
                <span className={`badge status-${p.status}`}>{p.status.replace('_', ' ')}</span>
              </div>
              {p.description && <p className="muted">{p.description}</p>}
              {p.address && <p className="meta">{p.address}</p>}
            </Link>
          </li>
        ))}
      </ul>
    </>
  )
}
