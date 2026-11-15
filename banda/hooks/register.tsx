import { atom, read, update } from 'claude-code'
import type { CoreEngineInterface, Register } from 'claude-code'

const COMANDO = 'banda'
const carpeta = atom({ plugin: 'statusline-banda', key: 'carpeta' } as const, null)
const rama = atom({ plugin: 'statusline-banda', key: 'rama' } as const, null)
const oculta = atom({ plugin: 'statusline-banda', key: 'oculta' } as const, false)

// /Users/ana/proy -> ~/proy. La barra evita que /Users/anabel pase por estar dentro de /Users/ana.
const abreviar = (ruta: string, home: string | undefined) =>
  home && (ruta === home || ruta.startsWith(`${home}/`)) ? `~${ruta.slice(home.length)}` : ruta

// Guarda la carpeta y su rama de git: 'no git' fuera de un repo o sin git, 'sin rama' con HEAD suelto.
const seguir = async ($: Pick<CoreEngineInterface, 'state' | 'process'>, cwd: string) => {
  await update($, carpeta, () => cwd)
  const actual = await $.process
    .run(['git', 'branch', '--show-current'], { cwd, timeoutMs: 2000 })
    .then(r => (r.exitCode === 0 ? r.stdout.trim() || 'sin rama' : 'no git'))
    .catch(() => 'no git')
  await update($, rama, () => actual)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: COMANDO,
      description: 'Muestra u oculta la banda de la carpeta de trabajo',
      argumentHint: '[on|off]',
    })
    // $.store guarda la elección entre sesiones; $.state es lo que redibuja la banda.
    const guardada = (await $.store.get('oculta')) === true
    await update($, oculta, () => guardada)
    await seguir($, e.cwd)

    return next(e)
  })

  on('command.run', { command: COMANDO }, async ($, e) => {
    const arg = e.args.trim()

    if (arg !== '' && arg !== 'on' && arg !== 'off') {
      return { text: `Uso: /${COMANDO} [on|off]. Sin argumento alterna.` }
    }

    const ocultar = arg === '' ? !(await read($, oculta)) : arg === 'off'
    await update($, oculta, () => ocultar)
    await $.store.set('oculta', ocultar)

    return {
      text: ocultar ? `Banda oculta; /${COMANDO} la trae de vuelta.` : 'Banda visible.',
    }
  })

  on('classic.CwdChanged', async ($, e, next) => {
    await seguir($, e.new_cwd)

    return next(e)
  }).catch(($, e, next) => next(e))

  // Red de seguridad: un `cd` del shell dentro del turno, por si CwdChanged no llegó.
  on('turn.complete', async ($, e, next) => {
    // El turno de un subagente trae su propia carpeta (un worktree): no es la de la sesión.
    if (e.agentId !== undefined) {
      return next(e)
    }

    // También recoge un cambio de rama hecho durante el turno.
    await seguir($, await $.session.cwd())

    return next(e)
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const ruta = await read($, carpeta)

    if (e.props.hasSurvey || ruta === null || (await read($, oculta))) {
      return next(e)
    }

    const home = await $.env.get('HOME')
    const actual = await read($, rama)
    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box
        flexDirection="row"
        justifyContent="space-between"
        width={e.surface === 'terminal' ? e.props.bodyColumns : undefined}
      >
        <Box flexDirection="row" flexShrink={1}>
          <Text>📁 </Text>
          {/* Si no cabe, se corta por el inicio: el final de la ruta es lo que distingue la carpeta. */}
          <Text wrap="truncate-start">{abreviar(ruta, home)}</Text>
        </Box>
        {/* La rama no se encoge: ante poco ancho, la que se corta es la ruta. */}
        {actual === null ? null : (
          <Box flexShrink={0}>
            <Text>{` rama:${actual}`}</Text>
          </Box>
        )}
      </Box>
    )
  })
}
