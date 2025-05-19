import Product from '#models/product'
import { HttpContext } from '@adonisjs/core/http'
import app from '@adonisjs/core/services/app'
import db from '@adonisjs/lucid/services/db'
import { unlink } from 'node:fs/promises'
import ProductService from '#services/product_service'
import { createProductValidator } from '#validators/product_create'
import env from '#start/env'
import { getUpdateProductSchema } from '#validators/product_update'
import vine from '@vinejs/vine'
import Transaction from '#models/transaction'
import { DateTime } from 'luxon'

export default class AdminProductController {
  // Create a new product
  async store({ request, response }: HttpContext) {
    // Validate the request data using the product validator
    const { image, ...data } = await request.validateUsing(createProductValidator)

    // Process and store the product image if provided
    if (image) {
      data.imageUrl = await ProductService.storePImage(image)
    }

    // Create the new product within a transaction
    const product = await db.transaction(async (trx) => {
      const newProduct = new Product()
      newProduct.useTransaction(trx)
      // Merge the validated data and save the product
      newProduct.merge(data)
      await newProduct.save()
      return newProduct
    })

    // Return a success response
    return response.created({
      message: 'Product created successfully',
      product,
    })
  }

  async update({ params, request, response }: HttpContext) {
    // Validate the incoming request using the update schema
    const updateProductValidator = vine.compile(getUpdateProductSchema(params.id))
    const { image, ...data } = await request.validateUsing(updateProductValidator)

    // Find the product by ID
    const product = await Product.findOrFail(params.id)

    // Capture the original stock value before updating the product
    const originalStock = product.stock

    // If a new image is uploaded
    if (image) {
      // Delete the existing image if present
      if (product.imageUrl) {
        const imagePath = product.imageUrl.replace(env.get('APP_URL'), '')
        const fullImagePath = app.makePath('storage', imagePath)
        await unlink(fullImagePath)
      }
      // Store the new image and update the imageUrl in data object
      data.imageUrl = await ProductService.storePImage(image)
    }

    // Start a transaction to update the product and record the stock transaction
    await db.transaction(async (trx) => {
      product.useTransaction(trx)

      // Update the product with new data
      await product.merge(data).save()

      // Check if the stock value has changed
      if (data.stock !== undefined && data.stock !== originalStock) {
        // Determine the transaction type based on the stock change
        let transactionType: 'addition' | 'removal' = 'addition'
        let quantity = data.stock - originalStock

        if (quantity < 0) {
          transactionType = 'removal'
          quantity = Math.abs(quantity)
        }

        // Create a new transaction in the transactions table
        await Transaction.create({
          productId: product.id,
          transactionType: transactionType,
          quantity: quantity,
          transactionDate: DateTime.now(),
        })
      }
    })

    return response.created({ message: 'Product Updated successfully', product })
  }

  // Delete a product
  async destroy({ params, response }: HttpContext) {
    const product = await Product.findOrFail(params.id)

    // Delete the image file if it exists
    if (product.imageUrl) {
      const imagePath = product.imageUrl.replace(env.get('APP_URL'), '')
      const fullImagePath = app.makePath('storage', imagePath)

      try {
        await unlink(fullImagePath)
      } catch (error) {
        // If the file is not found, log the error and proceed
        if (error.code !== 'ENOENT') {
          // Rethrow if it's a different error
          throw error
        }
        console.warn(`File not found: ${fullImagePath}`)
      }
    }

    await product.delete()
    return response.ok({ message: 'Product deleted successfully' })
  }
}
