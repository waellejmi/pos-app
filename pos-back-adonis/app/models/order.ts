import { DateTime } from 'luxon'
import { BaseModel, column, belongsTo, hasMany, manyToMany } from '@adonisjs/lucid/orm'
import type { BelongsTo, HasMany, ManyToMany } from '@adonisjs/lucid/types/relations'
import OrderItem from './orderitem.js'
import User from './user.js'
import Customer from './customer.js'
import Payment from './payment.js'
import Product from './product.js'

export default class Order extends BaseModel {
  @column({ isPrimary: true })
  declare id: number

  @column()
  declare orderNumber: string

  @column()
  declare paymentId: number

  @column()
  declare customerId: number | null

  @column()
  declare userId: number

  @column.dateTime({ autoCreate: false, autoUpdate: false })
  declare completedAt: DateTime | null

  @column()
  declare status: string

  @column()
  declare comments: string

  @column()
  declare shippingAddress: string

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  declare updatedAt: DateTime

  @hasMany(() => OrderItem)
  declare orderItems: HasMany<typeof OrderItem>

  @belongsTo(() => User, { foreignKey: 'userId' })
  declare user: BelongsTo<typeof User>

  @belongsTo(() => Customer, { foreignKey: 'customerId' })
  declare customer: BelongsTo<typeof Customer>

  @belongsTo(() => Payment, { foreignKey: 'paymentId' })
  declare payment: BelongsTo<typeof Payment>

  @manyToMany(() => Product, {
    pivotTable: 'order_items', // This is the pivot table
    pivotTimestamps: false,
  })
  declare products: ManyToMany<typeof Product>
}
