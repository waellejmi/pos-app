import vine from '@vinejs/vine'

export const createProductValidator = vine.compile(
  vine.object({
    name: vine.string().minLength(3).maxLength(255).isUnique({ table: 'products', column: 'name' }),
    barcode: vine.string().isUnique({ table: 'products', column: 'barcode' }).optional(),
    imageUrl: vine.string().optional(),
    image: vine.file({ extnames: ['png', 'jpg', 'jpeg', 'gif'], size: '5mb' }).optional(),
    description: vine.string().optional(),
    price: vine.number().min(0),
    discount: vine.number().min(0).optional(),
    cost: vine.number().min(0),
    stock: vine.number().min(0),
    minThreshold: vine.number().min(0),
    maxThreshold: vine.number().min(0).optional(),
    isActive: vine.boolean(),
    categoryId: vine.number().min(1).isExists({ table: 'categories', column: 'id' }),
    supplierId: vine.number().isExists({ table: 'suppliers', column: 'id' }),
  })
)
