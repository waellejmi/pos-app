import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'categories'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id').primary().notNullable() // Primary key
      table.string('name').notNullable() // Category name
      table.string('description').notNullable() // Description
      table.timestamp('created_at', { useTz: true }).defaultTo(this.now()).notNullable() // Created at
      table.timestamp('updated_at', { useTz: true }).defaultTo(this.now()).notNullable() // Updated at
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
