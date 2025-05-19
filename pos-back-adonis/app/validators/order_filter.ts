import vine from '@vinejs/vine'

// Define allowed status values

const sharedOrderFilterSchema = vine.object({
  search: vine.string().optional(), // Optional search term for orders
  status: vine.string().optional(),
  date: vine.date().optional(), // Optional end date for filtering
})

export const orderFilterValidator = vine.compile(sharedOrderFilterSchema)
