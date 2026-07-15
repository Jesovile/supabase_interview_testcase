import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { BrokenProjectCard } from '../components/BrokenProjectCard'
import { supabase, type Project } from '../lib/supabase'

// A project row plus its embedded assignments and each assignee's profile name.
// RLS on project_assignments/profiles means a worker only ever sees their own
// assignment here, while an admin sees every assignee on the project.
type ProjectWithAssignees = Project & {
  project_assignments: {
    user_id: string
    profiles: { full_name: string | null } | null
  }[]
}

export function Dashboard() {
  const { profile, user } = useAuth()
  const [projects, setProjects] = useState<ProjectWithAssignees[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let active = true
    ;(async () => {
      const { data, error } = await supabase
        .from('projects')
        // RLS transparently limits this to projects the user may see.
        // Embed each project's assignments and the assignee's display name.
        .select('*, project_assignments(user_id, profiles(full_name))')
        .order('created_at', { ascending: true })
      if (!active) return
      if (error) setError(error.message)
      else setProjects((data as ProjectWithAssignees[] | null) ?? [])
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

      {error && <p className="error">{error}</p>}
      {!loading && !error && projects.length === 0 && (
        <p className="muted">No projects are available to you yet.</p>
      )}

      <ul className="cards">
        <BrokenProjectCard />
        {projects.map((p) => (
          <li key={p.id} className="card">
            <Link to={`/projects/${p.id}`}>
              <div className="card-head">
                <h2>{p.name}</h2>
                <span className={`badge status-${p.status}`}>{p.status.replace('_', ' ')}</span>
              </div>
              {p.description && <p className="muted">{p.description}</p>}
              {p.address && <p className="meta">{p.address}</p>}
              <div className="assignees">
                {p.project_assignments.length > 0 ? (
                  p.project_assignments.map((a) => (
                    <span key={a.user_id} className="badge assignee">
                      {a.profiles?.full_name ?? 'Unknown user'}
                    </span>
                  ))
                ) : (
                  <span className="badge assignee unassigned">Unassigned</span>
                )}
              </div>
            </Link>
          </li>
        ))}
      </ul>
    </>
  )
}
