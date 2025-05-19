import Category from '#models/category'
import factory from '@adonisjs/lucid/factories'
import { faker } from '@faker-js/faker'
import { ProductFactory } from './product_factory.js'

export const CategoryFactory = factory
  .define(Category, ({}) => {
    return {
      name: faker.commerce.department(),
      description: faker.lorem.sentence(),
    }
  })
  .relation('products', () => ProductFactory)
  .build()
