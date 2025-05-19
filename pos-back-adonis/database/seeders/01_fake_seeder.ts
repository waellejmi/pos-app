import { BaseSeeder } from '@adonisjs/lucid/seeders'
import Database from '@adonisjs/lucid/services/db'
import { CategoryFactory } from '#database/factories/category_factory'
import { SupplierFactory } from '#database/factories/supplier_factory'
import { ProductFactory } from '#database/factories/product_factory'
import { CustomerFactory } from '#database/factories/customer_factory'
import { PaymentFactory } from '#database/factories/payment_factory'
import { UserFactory } from '#database/factories/user_factory'
import { OrderFactory } from '#database/factories/order_factory'
import { OrderItemFactory } from '#database/factories/order_item_factory'
import { DateTime } from 'luxon'

export default class extends BaseSeeder {
  async run() {
    await Database.transaction(async (trx) => {
      try {
        // Create categories, suppliers, customers, and users
        const categories = await CategoryFactory.createMany(6)
        const suppliers = await SupplierFactory.createMany(10)
        const customers = await CustomerFactory.createMany(8)
        const users = await UserFactory.createMany(5)

        // Create products and assign each to a single category
        const products = await Promise.all(
          Array.from({ length: 35 }, async () => {
            const supplier = this.#getRandomElement(suppliers)
            const category = this.#getRandomElement(categories) // Select a single category
            const product = await ProductFactory.merge({
              supplierId: supplier.id,
              categoryId: category.id, // Assign the category to the product
            }).create()

            return product
          })
        )

        // Create orders with payments and order items
        for (let i = 0; i < 15; i++) {
          const customer = this.#getRandomElement(customers)
          const user = this.#getRandomElement(users)
          const orderStatus = this.#getRandomElement([
            'pending',
            'processing',
            'completed',
            'cancelled',
          ])

          // Create payment for this order
          const payment = await PaymentFactory.merge({
            amount: 0, // We'll update this later
            status: this.#getRandomElement(['pending', 'paid']),
            paymentDate: DateTime.local(),
          }).create()

          const order = await OrderFactory.merge({
            customerId: customer.id,
            userId: user.id,
            paymentId: payment.id,
            status: orderStatus,
            shippingAddress: '123 Example Street',
          }).create()

          // Create order items with multiple products
          const numberOfItems = this.#getRandomInt(1, 5)
          let totalAmount = 0

          for (let j = 0; j < numberOfItems; j++) {
            const productCount = this.#getRandomInt(1, 3) // Number of products per order item
            const productsForItem = this.#getRandomElements(products, productCount)
            const quantity = this.#getRandomInt(1, 10)

            // Calculate totalPrice for all products in this order item
            let itemTotalPrice = 0
            for (const product of productsForItem) {
              const unitPrice = product.price
              itemTotalPrice += quantity * unitPrice
              await OrderItemFactory.merge({
                orderId: order.id,
                productId: product.id,
                quantity: quantity,
                unitPrice: unitPrice,
                totalPrice: quantity * unitPrice,
              }).create()
            }

            totalAmount += itemTotalPrice
          }

          // Update order and payment with total amount
          const taxAmount = totalAmount * 0.1 // Assuming 10% tax
          await payment
            .merge({
              amount: totalAmount + taxAmount,
              taxAmount: taxAmount,
            })
            .save()

          await payment.merge({ amount: totalAmount }).save()
        }

        await trx.commit()
      } catch (error) {
        console.error('Error during seeding:', error)
        await trx.rollback()
        throw error
      }
    })
  }

  #getRandomInt(min: number, max: number): number {
    return Math.floor(Math.random() * (max - min + 1)) + min
  }

  #getRandomElement<T>(array: T[]): T {
    return array[Math.floor(Math.random() * array.length)]
  }

  #getRandomElements<T>(array: T[], count: number): T[] {
    const shuffled = array.slice().sort(() => 0.5 - Math.random())
    return shuffled.slice(0, count)
  }
}
