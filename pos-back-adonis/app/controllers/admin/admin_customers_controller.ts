// start/controllers/CustomerController.ts

import Customer from '#models/customer'
import { customerUpdateValidator } from '#validators/customer'
import { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import vine from '@vinejs/vine'

export default class CustomerController {
  // Update an existing customer
  async update({ params, request, response }: HttpContext) {
    const updatecustomerValidator = vine.compile(customerUpdateValidator(params.id))

    const newCustomer = await request.validateUsing(updatecustomerValidator)
    const customer = await Customer.findOrFail(params.id)

    await db.transaction(async (trx) => {
      customer.useTransaction(trx)
      await customer.merge(newCustomer).save()
    })

    return response.created({ message: 'Customer  Updated successfully', customer })
  }
  // Delete a customer
  async destroy({ params, response }: HttpContext) {
    const customer = await Customer.findOrFail(params.id)
    await customer.delete()

    return response.ok({ message: 'Customer deleted successfully' })
  }
}
