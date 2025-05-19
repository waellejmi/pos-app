import Supplier from '#models/supplier'
import factory from '@adonisjs/lucid/factories'
import { faker } from '@faker-js/faker'
import { DateTime } from 'luxon'
import { ProductFactory } from './product_factory.js'

export const SupplierFactory = factory
  .define(Supplier, ({}) => {
    return {
      name: faker.company.name(),
      contactName: faker.person.fullName(),
      phone: faker.phone.number(),
      email: faker.internet.email(),
      address: faker.location.streetAddress(),
      createdAt: DateTime.fromJSDate(faker.date.past()), // Convert Date to DateTime
      updatedAt: DateTime.fromJSDate(faker.date.recent()),
    }
  })
  .relation('products', () => ProductFactory)
  .build()
