import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'orders'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id').primary().notNullable()
      table.string('order_number').notNullable()
      table
        .integer('payment_id')
        .unsigned()
        .references('id')
        .inTable('payments')
        .notNullable()
        .onDelete('CASCADE')
      table.integer('customer_id').unsigned().references('id').inTable('customers').nullable()
      table.integer('user_id').unsigned().references('id').inTable('users').notNullable()

      table.string('status').notNullable()
      table.string('comments').nullable()
      table.string('shipping_address').nullable()
      table.timestamp('completed_at').nullable()
      table.timestamp('created_at', { useTz: true }).notNullable().defaultTo(this.now())
      table.timestamp('updated_at').notNullable().defaultTo(this.now())
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
