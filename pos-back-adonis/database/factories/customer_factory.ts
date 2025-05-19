import Customer from '#models/customer'
import factory from '@adonisjs/lucid/factories'
import { faker } from '@faker-js/faker'

export const CustomerFactory = factory
  .define(Customer, ({}) => {
    return {
      name: faker.person.fullName(),
      email: faker.internet.email(),
      phone: faker.phone.number(),
      address: faker.location.streetAddress(),
    }
  })
  .build()
