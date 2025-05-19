import { Infer } from '@vinejs/vine/types'
import { categoryFilterValidator } from '#validators/category_filter'
import Category from '#models/category'
import Product from '#models/product'
import { TransactionClientContract } from '@adonisjs/lucid/types/database'

export default class CategoryService {
  static getFiltered(filters: Infer<typeof categoryFilterValidator>) {
    return Category.query()
      .if(filters.search, (query) => query.whereILike('name', `%${filters.search}%`))
      .orderBy('updatedAt', 'desc')
  }

  static async syncProducts(
    category: Category,
    productIds: number[],
    trx: TransactionClientContract
  ) {
    // Update products that should be in this category
    await Product.query({ client: trx })
      .whereIn('id', productIds)
      .update({ categoryId: category.id })

    // Remove this category from products that are no longer in it
    await Product.query({ client: trx })
      .where('categoryId', category.id)
      .whereNotIn('id', productIds)
      .update({ categoryId: null })
  }
}
