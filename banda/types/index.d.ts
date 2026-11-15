/** Ruta absoluta de la carpeta de la sesión; null hasta el primer session.start. */
export type Carpeta = string | null

declare module 'claude-code' {
  interface PluginState {
    'statusline-banda': { carpeta: Carpeta; oculta: boolean }
  }
}
