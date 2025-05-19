import { DateTime } from 'luxon'
import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import Product from './product.js'

export default class Transaction extends BaseModel {
  @column({ isPrimary: true })
  declare id: number

  @column()
  declare productId: number

  @column()
  declare transactionType: string // e.g., purchase, sale, adjustment

  @column()
  declare quantity: number

  @column.dateTime()
  declare transactionDate: DateTime

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime

  @belongsTo(() => Product, { foreignKey: 'productId' })
  declare product: BelongsTo<typeof Product>
}
