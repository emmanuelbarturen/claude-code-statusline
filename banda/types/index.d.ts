/** Ruta absoluta de la carpeta de la sesión; null hasta el primer session.start. */
export type Carpeta = string | null

/** Rama de git de esa carpeta; null fuera de un repo o con HEAD suelto. */
export type Rama = string | null

declare module 'claude-code' {
  interface PluginState {
    'statusline-banda': { carpeta: Carpeta; rama: Rama; oculta: boolean }
  }
}
