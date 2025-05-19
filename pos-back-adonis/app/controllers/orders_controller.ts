// start/controllers/UserOrderController.ts

import Order from '#models/order'
import OrderService from '#services/order_service'
import { orderValidator } from '#validators/order'
import { orderFilterValidator } from '#validators/order_filter'
import { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'
import { DateTime } from 'luxon'

export default class UserOrderController {
  // Get all orders
  async index({ request, response }: HttpContext) {
    const page = request.input('page', 1)
    const filters = await orderFilterValidator.validate(request.qs())

    try {
      const orders = await OrderService.getFiltered(filters).paginate(page, 15)

      // Construct the response
      const result = {
        orders: orders,
        filters,
      }

      return response.ok(result)
    } catch (error) {
      return response.status(500).json({ error: error.message })
    }
  }

  // Get details of a specific order
  async show({ params, response }: HttpContext) {
    const order = await Order.query()
      .where('id', params.id)
      .preload('customer')
      .preload('user', (query) => {
        query.select('id', 'fullName', 'phone', 'address', 'email')
      })
      .preload('payment')
      .preload('orderItems')
      .firstOrFail()

    return response.ok(order)
  }

  async store({ request, response }: HttpContext) {
    // Validate the incoming request data
    const validatedData = await request.validateUsing(orderValidator)
    // Extract the validated order data and order items
    const { orderItems, ...orderData } = validatedData

    // Adjust the data to match the expected type for Order.create
    const adjustedOrderData = {
      ...orderData,
      customerId: orderData.customerId ?? undefined,
      completedAt: orderData.completedAt ? DateTime.fromJSDate(orderData.completedAt) : null,
      comments: orderData.comments ?? undefined,
      shippingAddress: orderData.shippingAddress ?? undefined,
    }

    // Start a database transaction
    const order = await db.transaction(async (trx) => {
      // Create the order
      const newOrder = await Order.create(adjustedOrderData, { client: trx })

      // Sync order items
      await OrderService.syncOrderItems(newOrder, orderItems, trx)

      return newOrder
    })

    // Return a response with the created order
    return response.created({ message: 'Order created successfully', order })
  }
}
