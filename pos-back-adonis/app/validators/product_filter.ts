import vine from '@vinejs/vine'

const sharedProductFilterSchema = vine.object({
  search: vine.string().optional(), // Optional search term
  needsRestocking: vine.boolean().optional(), // Optional filter for products needing restocking
  isActive: vine.boolean().optional(),
})

export const productFilterValidator = vine.compile(sharedProductFilterSchema)
