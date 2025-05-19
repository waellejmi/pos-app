import vine from '@vinejs/vine'

export const customerValidator = vine.compile(
  vine.object({
    name: vine.string().maxLength(100),
    email: vine.string().email().normalizeEmail().isUnique({ table: 'customers', column: 'email' }),
    phone: vine.string().maxLength(12).optional(),
    address: vine.string().maxLength(250).optional(),
  })
)
export function customerUpdateValidator(customerId: number) {
  return vine.object({
    name: vine.string().maxLength(100).optional(),
    email: vine
      .string()
      .email()
      .normalizeEmail()
      .isUnique({
        table: 'customers',
        column: 'email',
        exceptionColumnId: { column: 'id', value: customerId },
      })
      .optional(),
    phone: vine.string().maxLength(12).optional(),
    address: vine.string().maxLength(250).optional(),
  })
}

const sharedCustomerFilterSchema = vine.object({
  search: vine.string().optional(), // Optional search term for orders
})

export const customerFilterValidator = vine.compile(sharedCustomerFilterSchema)
