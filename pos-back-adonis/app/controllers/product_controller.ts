import Product from '#models/product'
import ProductService from '#services/product_service'
import { productFilterValidator } from '#validators/product_filter'
import { HttpContext } from '@adonisjs/core/http'

export default class UserProductController {
  // Get all products (for normal users)
  async index({ request, response }: HttpContext) {
    const page = request.input('page', 1)
    const filters = await productFilterValidator.validate(request.qs())

    try {
      const products = await ProductService.getFiltered(filters).paginate(page, 15)

      // Construct the response
      const result = {
        products: products,
        filters,
      }

      return response.ok(result)
    } catch (error) {
      return response.status(500).json({ error: error.message })
    }
  }

  // Get a single product by ID (for normal u sers)
  async show({ params, response }: HttpContext) {
    const productId = params.id
    const product = await Product.query()
      .where('id', productId)
      .preload('supplier')
      .preload('category')
      .preload('transactions')
      .firstOrFail()

    return response.ok(product)
  }
}
