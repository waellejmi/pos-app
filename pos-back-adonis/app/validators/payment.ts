import vine from '@vinejs/vine'
import { DateTime } from 'luxon'

export const paymentValidator = vine.compile(
  vine.object({
    status: vine.string().maxLength(50), // Assuming a max length for status
    paymentDate: vine
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

    paymentMethod: vine.string().maxLength(50), // Assuming a max length for payment method
    amount: vine.number().positive(), // Ensures amount is positive
    taxAmount: vine.number().min(0), // Ensures taxAmount is not negative
  })
)
