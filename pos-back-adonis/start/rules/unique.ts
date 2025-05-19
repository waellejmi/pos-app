import type { FieldContext } from '@vinejs/vine/types'
import db from '@adonisjs/lucid/services/db'
import vine from '@vinejs/vine'
import { VineString, VineNumber } from '@vinejs/vine'

type Options = {
  table: string
  column: string
  exceptionColumnId?: {
    column: string
    value: number
  }
}

async function isUnique(value: unknown, options: Options, field: FieldContext) {
  if (typeof value !== 'string' && typeof value !== 'number') {
    return
  }

  const query = db.from(options.table).select(options.column).where(options.column, value)

  // If exceptionColumnId is provided, exclude the current record from uniqueness check
  if (options.exceptionColumnId) {
    query.whereNot(options.exceptionColumnId.column, options.exceptionColumnId.value)
  }

  const result = await query.first()

  if (result) {
    // Report that the value is NOT unique
    field.report('This {{ field }} is already taken', 'isUnique', field)
  }
}

export const isUniqueRule = vine.createRule(isUnique)

declare module '@vinejs/vine' {
  interface VineString {
    isUnique(options: Options): this
  }

  interface VineNumber {
    isUnique(options: Options): this
  }
}

VineString.macro('isUnique', function (this: VineString, options: Options) {
  return this.use(isUniqueRule(options))
})

VineNumber.macro('isUnique', function (this: VineNumber, options: Options) {
  return this.use(isUniqueRule(options))
})
