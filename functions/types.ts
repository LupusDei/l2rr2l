/**
 * Cloudflare Pages Functions environment types
 */

export interface Env {
  DB: D1Database
  ELEVENLABS_API_KEY?: string
  JWT_SECRET?: string
  ENVIRONMENT?: string
}

export interface D1Database {
  prepare(query: string): D1PreparedStatement
  dump(): Promise<ArrayBuffer>
  batch<T = unknown>(statements: D1PreparedStatement[]): Promise<D1Result<T>[]>
  exec(query: string): Promise<D1ExecResult>
}

export interface D1PreparedStatement {
  bind(...values: unknown[]): D1PreparedStatement
  first<T = unknown>(colName?: string): Promise<T | null>
  run(): Promise<D1Result>
  all<T = unknown>(): Promise<D1Result<T>>
  raw<T = unknown>(): Promise<T[]>
}

export interface D1Result<T = unknown> {
  results?: T[]
  success: boolean
  error?: string
  meta?: {
    duration: number
    changes: number
    last_row_id: number
    served_by: string
  }
}

export interface D1ExecResult {
  count: number
  duration: number
}

// Context type for Pages Functions
export type CFContext = EventContext<Env, string, unknown>
