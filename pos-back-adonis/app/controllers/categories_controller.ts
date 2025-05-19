// start/controllers/UserCategoryController.ts

import Category from '#models/category'
import { HttpContext } from '@adonisjs/core/http'

export default class UserCategoryController {
  // Get all categories
  async index({ response }: HttpContext) {
    const categories = await Category.query().orderBy('updatedAt', 'desc')
    return response.ok(categories)
  }

  // Get a specific category
  async show({ params, response }: HttpContext) {
    const category = await Category.query().where('id', params.id).preload('products').firstOrFail()

    return response.ok(category)
  }
}
