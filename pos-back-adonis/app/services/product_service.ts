import Product from '#models/product'
import { Infer } from '@vinejs/vine/types'
import { productFilterValidator } from '#validators/product_filter'

import app from '@adonisjs/core/services/app'
import { cuid } from '@adonisjs/core/helpers'
import { MultipartFile } from '@adonisjs/core/bodyparser'
import env from '#start/env'

export default class ProductService {
  static getFiltered(filters: Infer<typeof productFilterValidator>) {
    return Product.query()
      .if(filters.search, (query) => query.whereILike('name', `%${filters.search}%`))
      .if(filters.isActive !== undefined, (query) => {
        query.where('isActive', filters.isActive!)
      })
      .if(filters.needsRestocking, (query) => {
        query.whereRaw('(stock - min_threshold) < 10')
      })
      .preload('supplier')
      .preload('category')
      .orderBy('updatedAt', 'desc')
  }

  static async storePImage(pimage: MultipartFile) {
    const fileName = `${cuid()}.${pimage.extname}`

    await pimage.move(app.makePath('storage/uploads/product-images'), {
      name: fileName,
    })
    const baseUrl = env.get('APP_URL')
    return `${baseUrl}/uploads/product-images/${fileName}`
  }
}
