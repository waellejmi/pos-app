import customer from '#models/customer'
import { Infer } from '@vinejs/vine/types'
import { customerFilterValidator } from '#validators/customer_filter'

export default class CustomerService {
  static getFiltered(filters: Infer<typeof customerFilterValidator>) {
    return customer
      .query()
      .if(filters.search, (query) => query.whereILike('name', `%${filters.search}%`)) // Adjust based on actual fields
      .orderBy('updatedAt', 'desc')
  }
}
