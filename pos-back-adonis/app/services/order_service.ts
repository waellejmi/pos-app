import Order from '#models/order'
import { Infer } from '@vinejs/vine/types'
import { orderFilterValidator } from '#validators/order_filter'
import { DateTime } from 'luxon'
import { TransactionClientContract } from '@adonisjs/lucid/types/database'
import Transaction from '#models/transaction'

export default class OrderService {
  static getFiltered(filters: Infer<typeof orderFilterValidator>) {
    return Order.query()
      .if(filters.search, (query) => query.whereILike('order_number', `%${filters.search}%`)) // Adjust based on actual fields
      .if(filters.status, (query) => {
        const validStatuses = ['pending', 'processing', 'completed', 'cancelled']
        if (validStatuses.includes(filters.status!)) {
          query.where('status', filters.status!)
        }
      })
      .if(filters.date, (query) => {
        if (filters.date) {
          const formattedDate = DateTime.fromISO(filters.date.toISOString()).toFormat('yyyy-MM-dd')
          query.whereRaw('DATE(created_at) = ?', [formattedDate])
        }
      })
      .orderBy('updatedAt', 'desc')
  }

  static async syncOrderItems(
    order: Order,
    orderItems: Array<{ productId: number; quantity: number; unitPrice: number }>,
    trx: TransactionClientContract
  ) {
    const orderItemsData = orderItems.map((item) => ({
      product_id: item.productId, // Ensure column names match your schema
      order_id: order.id,
      quantity: item.quantity,
      unit_price: item.unitPrice,
      total_price: item.quantity * item.unitPrice,
    }))

    // Delete existing order items
    await trx.from('order_items').where('order_id', order.id).delete()

    // Insert new order items
    await trx.table('order_items').insert(orderItemsData)

    // Update product stock
    for (const item of orderItems) {
      // Fetch the product
      const product = await trx.from('products').where('id', item.productId).first()

      if (product) {
        // Calculate the new stock
        const newStock = product.stock - item.quantity

        // Update the product stock
        await trx.from('products').where('id', item.productId).update({ stock: newStock })

        // Log a sale transaction in the transactions table
        await Transaction.create(
          {
            productId: item.productId,
            transactionType: 'sale',
            quantity: item.quantity,
            transactionDate: DateTime.now(),
          },
          { client: trx }
        )
      }
    }
  }
}
