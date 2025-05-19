import Payment from '#models/payment'
import { paymentValidator } from '#validators/payment'
import { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import { DateTime } from 'luxon'

export default class PaymentController {
  async index({ response }: HttpContext) {
    const payments = await Payment.query()
    return response.ok(payments)
  }

  async store({ request, response }: HttpContext) {
    const { status, paymentDate, paymentMethod, amount, taxAmount } =
      await request.validateUsing(paymentValidator)

    // Convert paymentDate to a Luxon DateTime if it's a Date object
    const effectivePaymentDate = paymentDate ? DateTime.fromJSDate(paymentDate) : null

    // Wrap the creation process in a transaction
    const payment = await db.transaction(async (trx) => {
      // Create the payment record
      const newPayment = await Payment.create(
        {
          status,
          paymentDate: effectivePaymentDate,
          paymentMethod,
          amount,
          taxAmount,
        },
        { client: trx }
      )
      return newPayment
    })

    // Return a response with the created payment
    return response.created({
      message: 'Payment created successfully',
      payment,
    })
  }

  // Get details of a payment
  async show({ params, response }: HttpContext) {
    const payment = await Payment.findOrFail(params.id)
    return response.ok(payment)
  }

  // Update a payment record
  async update({ params, request, response }: HttpContext) {
    const payment = await Payment.findOrFail(params.id)
    const { amount, paymentMethod, paymentDate, status } = request.only([
      'amount',
      'paymentMethod',
      'paymentDate',
      'status',
    ])

    payment.amount = amount
    payment.paymentMethod = paymentMethod
    payment.paymentDate = paymentDate
    payment.status = status
    await payment.save()

    return response.ok({ message: 'Payment updated successfully', payment })
  }
}
