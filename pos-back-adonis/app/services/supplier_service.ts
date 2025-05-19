import { Infer } from '@vinejs/vine/types'
import { categoryFilterValidator } from '#validators/category_filter'
import Supplier from '#models/supplier'
import { TransactionClientContract } from '@adonisjs/lucid/types/database'
import Product from '#models/product'

export default class SupplierService {
  static getFiltered(filters: Infer<typeof categoryFilterValidator>) {
    return Supplier.query()
      .if(filters.search, (query) => query.whereILike('name', `%${filters.search}%`)) // Adjust based on actual fields

      .orderBy('updatedAt', 'desc')
  }
  static async syncProducts(
    supplier: Supplier,
    productIds: number[],
    trx: TransactionClientContract
  ) {
    // Update products that should be in this category
    await Product.query({ client: trx })
      .whereIn('id', productIds)
      .update({ supplierId: supplier.id })

    // Remove this category from products that are no longer in it
    await Product.query({ client: trx })
      .where('supplierId', supplier.id)
      .whereNotIn('id', productIds)
      .update({ supplierId: null })
  }
}
