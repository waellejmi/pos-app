import { DateTime } from 'luxon'
import { BaseModel, hasMany, column } from '@adonisjs/lucid/orm'
import type { HasMany } from '@adonisjs/lucid/types/relations'
import Product from './product.js'

export default class Supplier extends BaseModel {
  @column({ isPrimary: true })
  declare id: number

  @column()
  declare name: string

  @column()
  declare contactName: string

  @column()
  declare email: string

  @column()
  declare phone: string

  @column()
  declare address: string

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime

  @column.dateTime({ autoUpdate: true })
  declare updatedAt: DateTime

  @hasMany(() => Product)
  declare products: HasMany<typeof Product>
}
