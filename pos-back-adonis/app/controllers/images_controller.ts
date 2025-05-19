// app/Controllers/Http/ImagesController.ts

import { HttpContext } from '@adonisjs/core/http'
import path from 'node:path'
import fs from 'node:fs'
import app from '@adonisjs/core/services/app'

export default class ImagesController {
  async show({ params, response }: HttpContext) {
    const { filename } = params
    const imagePath = path.join(app.makePath('storage/uploads/product-images'), filename)

    if (fs.existsSync(imagePath)) {
      response.download(imagePath)
    } else {
      response.status(404).send('Image not found')
    }
  }
}
