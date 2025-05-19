import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'transactions'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id').primary().notNullable()
      table
        .integer('product_id')
        .unsigned()
        .references('products.id')
        .onDelete('CASCADE')
        .notNullable()
      table.enu('transaction_type', ['removal', 'addition', 'sale']).notNullable()
      table.integer('quantity').notNullable()
      table.timestamp('transaction_date').notNullable()
      table.timestamp('created_at').notNullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
