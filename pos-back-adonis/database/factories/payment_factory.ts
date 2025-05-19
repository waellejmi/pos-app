import Payment from '#models/payment'
import factory from '@adonisjs/lucid/factories'
import { faker } from '@faker-js/faker'
import { DateTime } from 'luxon'

export const PaymentFactory = factory
  .define(Payment, async () => {
    return {
      status: faker.helpers.arrayElement(['pending', 'completed']),
      paymentDate: DateTime.fromJSDate(faker.date.past()), // Use DateTime from Luxon
      paymentMethod: faker.helpers.arrayElement(['credit_card', 'cash']),
      amount: Number.parseFloat(faker.commerce.price({ min: 20, max: 500 })),
      taxAmount: Number.parseFloat(faker.commerce.price({ min: 5, max: 50 })),
    }
  })
  .build()
