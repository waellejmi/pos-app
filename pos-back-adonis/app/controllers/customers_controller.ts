// start/controllers/UserCustomerController.ts

import Customer from '#models/customer'
import CustomerService from '#services/customer_service'
import { customerValidator } from '#validators/customer'
import { customerFilterValidator } from '#validators/customer'
import { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'

export default class UserCustomerController {
  // Get all customers
  async index({ request, response }: HttpContext) {
    const page = request.input('page', 1)
    const filters = await customerFilterValidator.validate(request.qs())

    try {
      const customers = await CustomerService.getFiltered(filters).paginate(page, 15)

      // Construct the response
      const result = {
        customers: customers,
        filters,
      }

      return response.ok(result)
    } catch (error) {
      return response.status(500).json({ error: error.message })
    }
  }

  // Get a specific customer
  async show({ params, response }: HttpContext) {
    try {
      const customer = await Customer.findOrFail(params.id)
      return response.ok(customer)
    } catch (error) {
      return response.status(404).json({ message: 'Customer not found' })
    }
  }

  async store({ request, response }: HttpContext) {
    const { name, email, phone, address } = await request.validateUsing(customerValidator)

    // Wrap the creation process in a transaction
    const customer = await db.transaction(async (trx) => {
      // Create the customer record
      const newCustomer = await Customer.create({ name, email, phone, address }, { client: trx })
      return newCustomer
    })

    // Return a response with the created customer
    return response.created({ message: 'Customer created successfully', customer })
  }
}
