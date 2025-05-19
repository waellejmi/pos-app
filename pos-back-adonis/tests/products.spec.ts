import { test } from '@japa/runner'

test.group('Product tests', (group) => {
  group.setup(async () => {
    // Setup logic before running tests, such as seeding the database
  })

  group.teardown(async () => {
    // Cleanup logic after running tests
  })

  test('should get all products', async ({ client }) => {
    const response = await client.get('/api/products')
    response.assertStatus(200)
    response.assertBodyContains({
      products: [],
    })
  })

  test('should create a new product', async ({ client }) => {
    const response = await client.post('/api/products').json({
      name: 'New Product',
      price: 100,
      description: 'Product description',
    })
    response.assertStatus(201)
    response.assertBodyContains({
      message: 'Product created successfully',
    })
  })

  test('should update a product', async ({ client }) => {
    const response = await client.put('/api/products/1').json({
      name: 'Updated Product',
      price: 150,
    })
    response.assertStatus(200)
    response.assertBodyContains({
      message: 'Product updated successfully',
    })
  })

  test('should delete a product', async ({ client }) => {
    const response = await client.delete('/api/products/1')
    response.assertStatus(200)
    response.assertBodyContains({
      message: 'Product deleted successfully',
    })
  })
})
