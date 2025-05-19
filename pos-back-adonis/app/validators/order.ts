import { isExistsRule } from '#start/rules/exists'
import vine from '@vinejs/vine'
import { DateTime } from 'luxon'

export const orderValidator = vine.compile(
  vine.object({
    orderNumber: vine.string().maxLength(50).isUnique({ table: 'orders', column: 'order_number' }), // Assuming a max length for the order number
    paymentId: vine.number().use(isExistsRule({ table: 'payments', column: 'id' })), // Ensures payment exists
    customerId: vine
      .number()
      .use(isExistsRule({ table: 'customers', column: 'id' }))
      .optional()
      .nullable(), // Optional customer
    userId: vine.number().use(isExistsRule({ table: 'users', column: 'id' })), // Ensures user exists
    completedAt: vine
      .string()
      .nullable()
      .transform((value) => {
        if (!value) return null
        const date = DateTime.fromISO(value)
        if (!date.isValid) {
          // Throw an error or return a specific value indicating an invalid date
          throw new Error('Invalid date format')
        }
        return date.toJSDate()
      }),
    status: vine.string().maxLength(50), // Assuming a max length for status
    comments: vine.string().maxLength(255).nullable(), // Optional comments with max length
    shippingAddress: vine.string().maxLength(255).nullable(), // Assuming a max length for the shipping address

    orderItems: vine
      .array(
        vine.object({
          productId: vine.number().use(isExistsRule({ table: 'products', column: 'id' })), // Ensures product exists
          quantity: vine.number().min(1), // Ensures quantity is at least 1
          unitPrice: vine.number().positive(), // Ensures a positive unit price
          totalPrice: vine.number().positive(), // Ensures a positive unit price
        })
      )
      .minLength(1), // Ensures there is at least one order item
  })
)
