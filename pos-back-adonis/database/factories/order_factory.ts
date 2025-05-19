import Order from '#models/order'
import factory from '@adonisjs/lucid/factories'
import { DateTime } from 'luxon'
import { CustomerFactory } from './customer_factory.js'
import { PaymentFactory } from './payment_factory.js'
import { ProductFactory } from './product_factory.js'
import { UserFactory } from './user_factory.js'

export const OrderFactory = factory
  .define(Order, async ({ faker }) => {
    return {
      orderNumber: faker.string.alphanumeric(10),
      customerId: 1, // Placeholder value
      userId: 1, // Placeholder value
      completedAt: DateTime.fromJSDate(faker.date.past()),
      status: faker.helpers.arrayElement(['pending', 'completed', 'processing', 'cancelled']),
      comments: faker.lorem.sentence(),
      shippingAddress: faker.location.streetAddress(),
      createdAt: DateTime.local(),
    }
  })
  .relation('customer', () => CustomerFactory)
  .relation('payment', () => PaymentFactory)
  .relation('products', () => ProductFactory)
  .relation('user', () => UserFactory)
  .build()
