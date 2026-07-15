import type { ReactNode } from 'react'
import { UserMenu } from './UserMenu'

const COMPANY_NAME = 'Construction Projects Portal'

export function Layout({ children }: { children: ReactNode }) {
  return (
    <div className="app-shell">
      <header className="app-header">
        <span className="app-brand">{COMPANY_NAME}</span>
        <UserMenu />
      </header>
      <main className="page">{children}</main>
    </div>
  )
}
