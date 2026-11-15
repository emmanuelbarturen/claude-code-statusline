/** Ruta absoluta de la carpeta de la sesión; null hasta el primer session.start. */
export type Carpeta = string | null

/** Rama de git de esa carpeta, 'no git' fuera de un repo o 'sin rama' con HEAD suelto; null hasta el primer session.start. */
export type Rama = string | null

declare module 'claude-code' {
  interface PluginState {
    'statusline-banda': { carpeta: Carpeta; rama: Rama; oculta: boolean }
  }
}
