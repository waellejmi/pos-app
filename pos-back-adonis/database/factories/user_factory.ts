import Roles from '#enums/roles'
import User from '#models/user'
import factory from '@adonisjs/lucid/factories'

export const UserFactory = factory
  .define(User, ({ faker }) => {
    return {
      fullName: faker.person.fullName(),
      roleId: Roles.USER, // Default to role ID 1 (USER)
      email: faker.internet.email(),
      password: faker.internet.password(),
      phone: faker.phone.number(),
      address: faker.location.streetAddress(), // Ideally, use a hashed password here
    }
  })
  .build()
