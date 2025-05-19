import { DateTime } from 'luxon'
import { BaseModel, column, hasOne } from '@adonisjs/lucid/orm'
import type { HasOne } from '@adonisjs/lucid/types/relations'
import Order from './order.js'

export default class Payment extends BaseModel {
  @column({ isPrimary: true })
  declare id: number

  @column()
  declare status: string

  @column.dateTime({ autoCreate: false, autoUpdate: false })
  declare paymentDate: DateTime | null

  @column()
  declare paymentMethod: string

  @column()
  declare amount: number

  @column()
  declare taxAmount: number

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime

  @column.dateTime({ autoUpdate: true })
  declare updatedAt: DateTime

  @hasOne(() => Order, { foreignKey: 'paymentId' })
  declare order: HasOne<typeof Order>
}
