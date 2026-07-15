import { Link } from 'react-router-dom'

// A deliberately "failed" project card that is NOT backed by any database row.
// Its id is a well-formed UUID that does not exist in `projects`, so opening it
// drives ProjectDetail's `.single()` fetch to return zero rows and surface the
// raw PGRST116 error instead of a graceful "not found" — this is how F4 is
// reproduced. Rendered for every role, since it never touches RLS-gated data.
const MISSING_PROJECT_ID = '00000000-0000-0000-0000-000000000000'

export function BrokenProjectCard() {
  return (
    <li className="card">
      <Link to={`/projects/${MISSING_PROJECT_ID}`}>
        <div className="card-head">
          <h2>Legacy Import</h2>
          <span className="badge status-on_hold">on hold</span>
        </div>
        <p className="muted">Archived record — no longer backed by a project row.</p>
      </Link>
    </li>
  )
}
