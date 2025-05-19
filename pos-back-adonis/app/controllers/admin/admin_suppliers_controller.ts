// start/controllers/SupplierController.ts

import Supplier from '#models/supplier'
import SupplierService from '#services/supplier_service'
import { getUpdateSupplier, supplierValidator } from '#validators/supplier'
import { supplierFilterValidator } from '#validators/supplier'
import { inject } from '@adonisjs/core'
import { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import vine from '@vinejs/vine'

@inject()
export default class SupplierController {
  // Get all suppliers
  async index({ request, response }: HttpContext) {
    const page = request.input('page', 1)
    const filters = await supplierFilterValidator.validate(request.qs())

    try {
      const suppliers = await SupplierService.getFiltered(filters).paginate(page, 15)

      // Construct the response
      const result = {
        suppliers: suppliers,
        filters,
      }

      return response.ok(result)
    } catch (error) {
      return response.status(500).json({ error: error.message })
    }
  }

  // Get a specific supplier
  async show({ params, response }: HttpContext) {
    const supplier = await Supplier.findOrFail(params.id)
    return response.ok(supplier)
  }

  // Create a new supplier
  async store({ request, response }: HttpContext) {
    const supplier = await request.validateUsing(supplierValidator)

    // Wrap the creation process in a transaction
    const newSupplier = await db.transaction(async (trx) => {
      // Create the Supplier record
      return await Supplier.create(supplier, { client: trx })
    })

    // Return a response with the created Supplier
    return response.created({ message: 'Supplier created successfully', newSupplier })
  }

  // Update a supplier
  async update({ params, request, response }: HttpContext) {
    const updateSupplierValidator = vine.compile(getUpdateSupplier(params.id))

    const data = await request.validateUsing(updateSupplierValidator)
    const supplier = await Supplier.findOrFail(params.id)

    await db.transaction(async (trx) => {
      supplier.useTransaction(trx)
      await supplier
        .merge({
          name: data.name,
          contactName: data.contactName,
          email: data.email,
          phone: data.phone,
          address: data.address,
        })
        .save()

      if (data.products) {
        await SupplierService.syncProducts(supplier, data.products, trx)
      }
    })

    // Reload the category with its products
    await supplier.load('products')

    return response.ok({ message: 'Supplier updated successfully', supplier })
  }

  // Delete a supplier
  async destroy({ params, response }: HttpContext) {
    const supplier = await Supplier.findOrFail(params.id)
    await supplier.delete()

    return response.ok({ message: 'Supplier deleted successfully' })
  }
}
