import Order from '#models/order'
import Product from '#models/product'
import OrderItem from '#models/orderitem'
import factory from '@adonisjs/lucid/factories'

export const OrderItemFactory = factory
  .define(OrderItem, async ({ faker }) => {
    // Fetch or create an order and a product
    const order = await Order.query().firstOrFail()
    const product = await Product.query().firstOrFail()

    const quantity = faker.number.int({ min: 1, max: 10 })
    const unitPrice = product.price
    const totalPrice = quantity * unitPrice

    return {
      orderId: order.id,
      productId: product.id,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    }
  })

  .build()
