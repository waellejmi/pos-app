import vine from '@vinejs/vine'

export const supplierValidator = vine.compile(
  vine.object({
    name: vine.string().maxLength(100).isUnique({ table: 'suppliers', column: 'name' }),
    contactName: vine.string().maxLength(100),
    email: vine.string().email().normalizeEmail().isUnique({ table: 'suppliers', column: 'email' }),
    phone: vine.string().maxLength(15).optional(),
    address: vine.string().maxLength(250).optional(),
  })
)

export function getUpdateSupplier(supplierId: number) {
  return vine.object({
    name: vine
      .string()
      .maxLength(100)
      .isUnique({
        table: 'suppliers',
        column: 'name',
        exceptionColumnId: { column: 'id', value: supplierId },
      }),
    contactName: vine.string().maxLength(100),
    email: vine
      .string()
      .email()
      .normalizeEmail()
      .isUnique({
        table: 'suppliers',
        column: 'email',
        exceptionColumnId: { column: 'id', value: supplierId },
      }),
    phone: vine.string().maxLength(15).optional(),
    address: vine.string().maxLength(250).optional(),

    products: vine.array(vine.number()).optional(),
  })
}

export const supplierFilterValidator = vine.compile(
  vine.object({
    search: vine.string().optional(), // Optional search term for orders
  })
)
