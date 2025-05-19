// start/controllers/OrderController.ts

import Order from '#models/order'

import { HttpContext } from '@adonisjs/core/http'

export default class OrderController {
  async destroy({ params, response }: HttpContext) {
    const order = await Order.findOrFail(params.id)
    await order.delete()

    return response.ok({ message: 'Order deleted successfully' })
  }
}
