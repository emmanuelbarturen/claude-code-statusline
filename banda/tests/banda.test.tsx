import { expect, mock, test } from 'claude-code/testing'
import type { TestBody } from 'claude-code/testing'

type Motor = Parameters<TestBody>[0]
type On = Parameters<TestBody>[1]

const BANDA = {
  plugin: 'statusline-banda',
  component: 'AbovePrompt',
  surface: 'terminal',
  props: {
    hasSurvey: false,
    isCollapsed: false,
    isWorking: false,
    maxRows: 10,
    bodyColumns: 80,
    scroll: { offset: 0, bodyRows: 10 },
    view: {},
  },
} as const

const COMANDO = {
  command: 'banda',
  origin: { kind: 'composer' },
  presentation: { isFullscreen: false, columns: 80 },
} as const

// Lo que el motor contesta bajo el mod. Va antes de la primera llamada a `$`: después ya no se admite.
// `rama` es lo que git contesta; sin ella, git falla como fuera de un repo.
const motor = (on: On, guardado: Record<string, unknown> = {}, rama?: string) => {
  on('process.run', () => ({
    value: {
      exitCode: rama === undefined ? 128 : 0,
      stdout: rama === undefined ? '' : `${rama}\n`,
      stderr: '',
      isStdoutTruncated: false,
      isStderrTruncated: false,
    },
  }))
  mock.env(on, { HOME: '/Users/ana' })
  mock.store(on, guardado)
  on('command.register', () => ({ value: { command: 'banda' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
}

const iniciar = ($: Motor, cwd: string) => $.session.start({ cwd, surface: 'terminal', isInteractive: true })

// La ruta que la banda dibuja, o undefined si no dibuja nada.
const ruta = async ($: Motor) => {
  const ui = await $.ui.mount(BANDA)
  const texto = (await ui.find({ type: 'Text', text: /\// }))?.text
  await ui.unmount()

  return texto
}

// La rama que la banda dibuja, o undefined si no dibuja ninguna.
const rama = async ($: Motor) => {
  const ui = await $.ui.mount(BANDA)
  const texto = (await ui.find({ type: 'Text', text: /⎇/ }))?.text
  await ui.unmount()

  return texto
}

test('en un repo de git la banda muestra la rama', async ($, on) => {
  motor(on, {}, 'main')
  await iniciar($, '/Users/ana/proy')

  expect(await ruta($)).toBe('~/proy')
  expect(await rama($)).toBe(' ⎇ main')
})

test('fuera de un repo de git la banda no muestra rama', async ($, on) => {
  motor(on)
  await iniciar($, '/Users/ana/proy')

  expect(await ruta($)).toBe('~/proy')
  expect(await rama($)).toBeUndefined()
})

test('la carpeta dentro de HOME se abrevia con ~', async ($, on) => {
  motor(on)
  await iniciar($, '/Users/ana/proy')

  expect(await ruta($)).toBe('~/proy')
})

test('una carpeta que solo comparte prefijo con HOME queda entera', async ($, on) => {
  motor(on)
  await iniciar($, '/Users/anabel/proy')

  expect(await ruta($)).toBe('/Users/anabel/proy')
})

test('al terminar un turno la banda sigue a la carpeta nueva', async ($, on) => {
  motor(on)
  on('session.cwd', () => ({ value: '/Users/ana/otra' }))
  on('turn.complete', () => ({ text: '' }))
  await iniciar($, '/Users/ana/proy')

  await $.turn.complete({ reason: 'answer', answer: '', durationMs: 1, isAborted: false, turnId: 't1' })

  expect(await ruta($)).toBe('~/otra')
})

test('/banda off la oculta, on la muestra y sin argumento alterna', async ($, on) => {
  motor(on)
  await iniciar($, '/Users/ana/proy')

  await $.command.run({ ...COMANDO, args: 'off' })
  expect(await ruta($)).toBeUndefined()

  await $.command.run({ ...COMANDO, args: 'on' })
  expect(await ruta($)).toBe('~/proy')

  await $.command.run({ ...COMANDO, args: '' })
  expect(await ruta($)).toBeUndefined()
})

test('un argumento desconocido no cambia nada y explica el uso', async ($, on) => {
  motor(on)
  await iniciar($, '/Users/ana/proy')

  const { text } = await $.command.run({ ...COMANDO, args: 'apagar' })

  expect(text).toMatch(/Uso: \/banda/)
  expect(await ruta($)).toBe('~/proy')
})

test('la banda oculta en una sesión anterior arranca oculta', async ($, on) => {
  motor(on, { oculta: true })
  await iniciar($, '/Users/ana/proy')

  expect(await ruta($)).toBeUndefined()
})
