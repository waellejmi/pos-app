import { DateTime } from 'luxon'
import { BaseModel, belongsTo, column, hasMany, manyToMany } from '@adonisjs/lucid/orm'
import type { BelongsTo, HasMany, ManyToMany } from '@adonisjs/lucid/types/relations'
import Supplier from './supplier.js'
import Category from './category.js'
import Order from './order.js'
import Transaction from './transaction.js'

export default class Product extends BaseModel {
  @column({ isPrimary: true })
  declare id: number

  @column()
  declare name: string

  @column()
  declare barcode: string

  @column()
  declare imageUrl: string

  @column()
  declare description: string

  @column()
  declare price: number

  @column()
  declare discount: number

  @column()
  declare cost: number

  @column()
  declare stock: number // Current stock

  @column()
  declare minThreshold: number // Minimum threshold

  @column()
  declare maxThreshold: number // Maximum threshold

  @column()
  declare isActive: boolean

  @column()
  declare supplierId: number

  @column()
  declare categoryId: number

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime

  @column.dateTime({ autoUpdate: true })
  declare updatedAt: DateTime

  @hasMany(() => Transaction)
  declare transactions: HasMany<typeof Transaction>

  @belongsTo(() => Supplier, { foreignKey: 'supplierId' })
  declare supplier: BelongsTo<typeof Supplier>

  @belongsTo(() => Category, { foreignKey: 'categoryId' })
  declare category: BelongsTo<typeof Category>

  @manyToMany(() => Order, {
    pivotTable: 'order_items',
    pivotTimestamps: true,
  })
  declare orders: ManyToMany<typeof Order>
}
