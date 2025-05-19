import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'products'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id').primary().notNullable()
      table.string('name').notNullable()
      table.string('barcode').notNullable()
      table.string('image_url').notNullable().defaultTo('')
      table.string('description').notNullable().defaultTo('')
      table
        .integer('supplier_id')
        .unsigned()
        .references('suppliers.id')
        .notNullable()
        .onDelete('SET NULL')
      table
        .integer('category_id')
        .unsigned()
        .references('categories.id')
        .notNullable()
        .onDelete('SET NULL')

      table.decimal('price', 10, 2).notNullable()
      table.decimal('discount', 5, 2).defaultTo(0.0)
      table.decimal('cost', 10, 2).notNullable()

      table.integer('stock').defaultTo(0)
      table.integer('min_threshold').defaultTo(0)
      table.integer('max_threshold').defaultTo(0)

      table.boolean('is_active').notNullable().defaultTo(true)

      table.timestamp('created_at').notNullable()
      table.timestamp('updated_at').notNullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
