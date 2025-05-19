// start/controllers/UserSupplierController.ts

import Supplier from '#models/supplier'
import { HttpContext } from '@adonisjs/core/http'

export default class UserSupplierController {
  // Get all suppliers
  async index({ response }: HttpContext) {
    const suppliers = await Supplier.all()
    return response.ok(suppliers)
  }

  // Get details of a specific supplier
  async show({ params, response }: HttpContext) {
    const supplier = await Supplier.query().where('id', params.id).preload('products').firstOrFail()

    return response.ok(supplier)
  }
}
