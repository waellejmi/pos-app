import Product from '#models/product'
import factory from '@adonisjs/lucid/factories'
import { CategoryFactory } from './category_factory.js'
import { OrderFactory } from './order_factory.js'
import { SupplierFactory } from './supplier_factory.js'

export const ProductFactory = factory
  .define(Product, async ({ faker }) => {
    return {
      name: faker.commerce.productName(),
      barcode: faker.string.numeric(12), // Updated method
      imageUrl: faker.image.url(), // Updated method
      description: faker.lorem.sentence(),
      price: Number.parseFloat(faker.commerce.price({ min: 10, max: 100 })), // Updated method
      discount: faker.number.int({ min: 0, max: 50 }), // Updated method
      cost: Number.parseFloat(faker.commerce.price({ min: 5, max: 50 })), // Updated method
      stock: faker.number.int({ min: 1, max: 100 }), // Updated method
      minThreshold: faker.number.int({ min: 5, max: 20 }), // Updated method
      maxThreshold: faker.number.int({ min: 50, max: 200 }), // Updated method
      isActive: faker.datatype.boolean(), // Ensure this is a number
    }
  })
  .relation('category', () => CategoryFactory)
  .relation('orders', () => OrderFactory)
  .relation('supplier', () => SupplierFactory)
  .build()
