import vine from '@vinejs/vine'

export const categoryValidator = vine.compile(
  vine.object({
    name: vine.string().maxLength(100).isUnique({ table: 'categories', column: 'name' }),
    description: vine.string().maxLength(200),
  })
)
export function getUpdateCategory(categoryId: number) {
  return vine.object({
    name: vine
      .string()
      .maxLength(100)
      .isUnique({
        table: 'categories',
        column: 'name',
        exceptionColumnId: { column: 'id', value: categoryId },
      }),
    description: vine.string().maxLength(200),
    products: vine.array(vine.number()).optional(),
  })
}

export const categoryFilterValidator = vine.compile(
  vine.object({
    search: vine.string().optional(), // Optional search term for orders
  })
)
