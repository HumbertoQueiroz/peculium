import { readFileSync } from 'node:fs'
import { converter, inGamut, parse, wcagContrast } from 'culori'
import { describe, expect, it } from 'vitest'

type Mode = Map<string, string>

const css = readFileSync(new URL('./theme.css', import.meta.url), 'utf8')
const toRgb = converter('rgb')
const COLOR_VALUE = /^oklch\(/

function readBlock(selector: string): Mode {
  const start = css.indexOf(`${selector} {`)
  const body = css.slice(start, css.indexOf('\n}', start))
  const variables: Mode = new Map()
  for (const [, name, value] of body.matchAll(/^\s+--([\w-]+):\s*(.+);/gm)) {
    variables.set(name, value.trim())
  }
  return variables
}

const light = readBlock(':root')
const dark = readBlock('.dark')
const modes = { light, dark }

function colorOf(mode: Mode, name: string) {
  const value = mode.get(name) ?? light.get(name)
  if (value === undefined) throw new Error(`--${name} is not defined`)
  const alias = value.match(/^var\(--([\w-]+)\)$/)
  return alias ? colorOf(mode, alias[1]) : parse(value)
}

const colorNames = (mode: Mode) =>
  [...mode].filter(([, value]) => COLOR_VALUE.test(value)).map(([name]) => name)

const STATES = ['payable', 'overdue', 'receivable', 'paid', 'positive', 'warning', 'info']

const TEXT_PAIRS: [string, string][] = [
  ['foreground', 'background'],
  ['foreground', 'card'],
  ['card-foreground', 'card'],
  ['popover-foreground', 'popover'],
  ['muted-foreground', 'background'],
  ['muted-foreground', 'card'],
  ['muted-foreground', 'muted'],
  ['secondary-foreground', 'secondary'],
  ['primary-foreground', 'primary'],
  ['accent-foreground', 'accent'],
  ['destructive-foreground', 'destructive'],
  ['negative', 'card'],
  ...STATES.flatMap((state): [string, string][] => [
    [state, 'card'],
    [state, `${state}-muted`],
  ]),
]

const CONTROL_PAIRS: [string, string][] = [
  ['input', 'background'],
  ['input', 'card'],
  ['ring', 'background'],
  ['ring', 'card'],
]

describe('theme colors', () => {
  it('defines the same colors in light and dark', () => {
    const aliases = ['negative']
    const lightOnly = colorNames(light).filter((name) => !dark.has(name) && !aliases.includes(name))
    expect(lightOnly).toEqual([])
  })

  it.each(Object.entries(modes))('uses no pure white or black in %s', (_, mode) => {
    for (const name of colorNames(mode)) {
      const { r, g, b } = toRgb(colorOf(mode, name))
      const isWhite = [r, g, b].every((channel) => channel > 0.995)
      const isBlack = [r, g, b].every((channel) => channel < 0.005)
      expect({ name, isWhite, isBlack }).toEqual({ name, isWhite: false, isBlack: false })
    }
  })

  it('writes no white or black as a literal', () => {
    const withoutComments = css.replace(/\/\*[\s\S]*?\*\//g, '')
    expect(withoutComments).not.toMatch(/#(?:f{3}|f{6}|0{3}|0{6})\b|\b(?:white|black)\b/i)
  })

  it.each(Object.entries(modes))('stays inside the sRGB gamut in %s', (_, mode) => {
    const outside = colorNames(mode).filter((name) => !inGamut('rgb')(colorOf(mode, name)))
    expect(outside).toEqual([])
  })

  describe.each(Object.entries(modes))('contrast in %s', (_, mode) => {
    it.each(TEXT_PAIRS)('text --%s on --%s reaches 4.5:1', (foreground, background) => {
      const ratio = wcagContrast(colorOf(mode, foreground), colorOf(mode, background))
      expect(ratio).toBeGreaterThanOrEqual(4.5)
    })

    it.each(CONTROL_PAIRS)('control --%s on --%s reaches 3:1', (foreground, background) => {
      const ratio = wcagContrast(colorOf(mode, foreground), colorOf(mode, background))
      expect(ratio).toBeGreaterThanOrEqual(3)
    })
  })
})
