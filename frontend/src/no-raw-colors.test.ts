import { readdirSync, readFileSync } from 'node:fs'
import { join, relative } from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'

const SOURCE_ROOT = fileURLToPath(new URL('.', import.meta.url))
const SOURCE_FILE = /\.(?:ts|tsx|css)$/
const IGNORED = [/\.test\.tsx?$/, /[\\/]generated[\\/]/, /[\\/]styles[\\/]theme\.css$/]

const PALETTE_CLASS =
  /\b(?:bg|text|border|ring|fill|stroke|from|to|via|divide|outline|decoration|accent|caret)-(?:slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-\d{2,3}\b/
const PURE_UTILITY =
  /\b(?:bg|text|border|ring|fill|stroke|from|to|via|divide|outline|shadow|decoration|accent|caret)-(?:black|white)\b/
const HEX_LITERAL = /(?<![&\w/])#(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b/

const RULES: [string, RegExp][] = [
  ['Tailwind palette class: use a role from theme.css (bg-card, text-payable...)', PALETTE_CLASS],
  ['pure black or white utility: use a role (bg-overlay, text-primary-foreground...)', PURE_UTILITY],
  ['hex color literal: define it in theme.css and use the role', HEX_LITERAL],
]

function listSourceFiles(directory: string): string[] {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name)
    if (entry.isDirectory()) return listSourceFiles(path)
    return SOURCE_FILE.test(entry.name) && !IGNORED.some((pattern) => pattern.test(path)) ? [path] : []
  })
}

describe('colors in the source', () => {
  it('come only from theme roles', () => {
    const violations = listSourceFiles(SOURCE_ROOT).flatMap((file) => {
      const lines = readFileSync(file, 'utf8').split('\n')
      return lines.flatMap((line, index) =>
        RULES.filter(([, pattern]) => pattern.test(line)).map(
          ([message]) => `${relative(SOURCE_ROOT, file)}:${index + 1} ${message}`,
        ),
      )
    })
    expect(violations).toEqual([])
  })
})
