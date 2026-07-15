import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { supabase, type Project, type ProjectStage } from '../lib/supabase'

export function ProjectDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [project, setProject] = useState<Project | null>(null)
  const [stages, setStages] = useState<ProjectStage[]>([])
  const [nextId, setNextId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!id) return
    let active = true
    ;(async () => {
      setLoading(true)
      // All three queries are RLS-gated; a non-visible project simply returns nothing.
      // The ids query mirrors the Dashboard ordering so "Next" walks the same list.
      const [projectRes, stagesRes, idsRes] = await Promise.all([
        supabase.from('projects').select('*').eq('id', id).single(),
        supabase
          .from('project_stages')
          .select('*')
          .eq('project_id', id)
          .order('sequence', { ascending: true }),
        supabase.from('projects').select('id').order('created_at', { ascending: true }),
      ])
      if (!active) return
      if (projectRes.error) setError(projectRes.error.message)
      else if (stagesRes.error) setError(stagesRes.error.message)
      else {
        setProject(projectRes.data)
        setStages(stagesRes.data ?? [])
        // Wrap around to the first project once the last one is reached.
        const ids = (idsRes.data ?? []).map((p) => p.id)
        const idx = ids.indexOf(id)
        setNextId(ids.length > 1 && idx !== -1 ? ids[(idx + 1) % ids.length] : null)
      }
      setLoading(false)
    })()
    return () => {
      active = false
    }
  }, [id])

  if (loading) return <p>Loading…</p>
  if (error) return <p className="error">{error}</p>
  if (!project)
    return (
      <>
        <p className="muted">Project not found or not available to you.</p>
        <Link to="/">← Back to projects</Link>
      </>
    )

  return (
    <>
      {nextId && (
        <button type="button" className="back" onClick={() => navigate(`/projects/${nextId}`)}>
          Next →
        </button>
      )}
      <header className="topbar">
        <div>
          <h1>{project.name}</h1>
          <p className="muted">
            <span className={`badge status-${project.status}`}>
              {project.status.replace('_', ' ')}
            </span>
            {project.address && <span className="meta"> {project.address}</span>}
          </p>
        </div>
      </header>
      {project.description && <p>{project.description}</p>}

      <h2>Stages</h2>
      {stages.length === 0 ? (
        <p className="muted">No stages defined for this project.</p>
      ) : (
        <ol className="stages">
          {stages.map((s) => (
            <li key={s.id} className="stage">
              <div>
                <strong>{s.name}</strong>
                {(s.start_date || s.end_date) && (
                  <span className="meta">
                    {' '}
                    {s.start_date ?? '…'} → {s.end_date ?? '…'}
                  </span>
                )}
              </div>
              <span className={`badge stage-${s.status}`}>{s.status.replace('_', ' ')}</span>
            </li>
          ))}
        </ol>
      )}
    </>
  )
}
