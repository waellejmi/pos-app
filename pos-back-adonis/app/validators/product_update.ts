import vine from '@vinejs/vine'

export function getUpdateProductSchema(productId: number) {
  return vine.object({
    name: vine
      .string()
      .minLength(3)
      .maxLength(255)
      .isUnique({
        table: 'products',
        column: 'name',
        exceptionColumnId: { column: 'id', value: productId },
      })
      .optional(),
    barcode: vine
      .string()
      .isUnique({
        table: 'products',
        column: 'barcode',
        exceptionColumnId: { column: 'id', value: productId },
      })
      .optional(),
    imageUrl: vine.string().optional(),
    image: vine.file({ extnames: ['png', 'jpg', 'jpeg', 'gif'], size: '5mb' }).optional(),
    description: vine.string().optional(),
    price: vine.number().min(0).optional(),
    discount: vine.number().min(0).optional(),
    cost: vine.number().min(0).optional(),
    stock: vine.number().min(0).optional(),
    minThreshold: vine.number().min(0).optional(),
    maxThreshold: vine.number().min(0).optional(),
    isActive: vine.boolean().optional(),
    categoryId: vine.number().min(1).isExists({ table: 'categories', column: 'id' }).optional(),
    supplierId: vine.number().isExists({ table: 'suppliers', column: 'id' }).optional(),
  })
}
