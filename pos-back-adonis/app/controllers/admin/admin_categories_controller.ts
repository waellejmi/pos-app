// start/controllers/CategoryController.ts

import Category from '#models/category'
import CategoryService from '#services/category_service'
import { categoryValidator, getUpdateCategory } from '#validators/category'
import { categoryFilterValidator } from '#validators/category'
import { inject } from '@adonisjs/core'
import { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import vine from '@vinejs/vine'

@inject()
export default class CategoryController {
  // Get all categories
  async index({ request, response }: HttpContext) {
    const page = request.input('page', 1)
    const filters = await categoryFilterValidator.validate(request.qs())

    try {
      const categories = await CategoryService.getFiltered(filters).paginate(page, 15)

      // Construct the response
      const result = {
        categories: categories,
        filters,
      }

      return response.ok(result)
    } catch (error) {
      return response.status(500).json({ error: error.message })
    }
  }

  // Get a specific category
  async show({ params, response }: HttpContext) {
    const category = await Category.findOrFail(params.id)
    return response.ok(category)
  }

  async store({ request, response }: HttpContext) {
    const category = await request.validateUsing(categoryValidator)

    // Wrap the creation process in a transaction
    const newCategory = await db.transaction(async (trx) => {
      // Create the category record
      return await Category.create(category, { client: trx })
    })

    // Return a response with the created category
    return response.created({ message: 'Category created successfully', newCategory })
  }

  // Update a category
  async update({ params, request, response }: HttpContext) {
    const updateCategoryValidator = vine.compile(getUpdateCategory(params.id))

    const data = await request.validateUsing(updateCategoryValidator)
    const category = await Category.findOrFail(params.id)

    await db.transaction(async (trx) => {
      category.useTransaction(trx)
      await category
        .merge({
          name: data.name,
          description: data.description,
        })
        .save()

      if (data.products) {
        await CategoryService.syncProducts(category, data.products, trx)
      }
    })

    // Reload the category with its products
    await category.load('products')

    return response.ok({ message: 'Category updated successfully', category })
  }

  // Delete a category
  async destroy({ params, response }: HttpContext) {
    const category = await Category.findOrFail(params.id)
    await category.delete()

    return response.ok({ message: 'Category deleted successfully' })
  }
}
