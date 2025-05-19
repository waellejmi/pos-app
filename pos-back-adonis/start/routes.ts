import { middleware } from './kernel.js'
import router from '@adonisjs/core/services/router'

// Dynamically import controllers
const AuthController = () => import('#controllers/auth/auth_controller')
const AdminDashboardController = () => import('#controllers/admin/admin_dashboard_controller')
const AdminProductController = () => import('#controllers/admin/admin_product_controller')
const AdminSupplierController = () => import('#controllers/admin/admin_suppliers_controller')
const AdminCategoryController = () => import('#controllers/admin/admin_categories_controller')
const AdminCustomerController = () => import('#controllers/admin/admin_customers_controller')
const AdminOrderController = () => import('#controllers/admin/admin_orders_controller')
const PaymentController = () => import('#controllers/payments_controller')
const CategoryController = () => import('#controllers/categories_controller')
const OrderController = () => import('#controllers/orders_controller')
const CustomerController = () => import('#controllers/customers_controller')
const SupplierController = () => import('#controllers/suppliers_controller')
const ProductController = () => import('#controllers/product_controller')
const ImagesController = () => import('#controllers/images_controller')

// Authentication routes
router.group(() => {
  router.post('/api/register', [AuthController, 'register']).as('auth.register')
  router.post('/api/login', [AuthController, 'login']).as('auth.login')
  router.delete('/api/logout', [AuthController, 'logout']).as('auth.logout').use(middleware.auth())
  router.get('/api/me', [AuthController, 'me']).as('auth.me').use(middleware.auth())
})

// User-specific routes
router
  .group(() => {
    router.get('user/me', [AuthController, 'me']).as('user.me')
    router.put('user/me', [AuthController, 'update']).as('user.update')
  })
  .prefix('/api/')
  .use(middleware.auth())

//  Admin  Resources  Routes FOR CRUD OPER
router
  .group(() => {
    router.get('/', [AdminDashboardController, 'handle']).as('dashboard')
    router.resource('/products', AdminProductController).apiOnly().as('admin.products')
    router.resource('/orders', AdminOrderController).apiOnly().as('orders')
    router.resource('/suppliers', AdminSupplierController).apiOnly().as('suppliers')
    router.resource('/customers', AdminCustomerController).apiOnly().as('customers')
    router.resource('/categories', AdminCategoryController).apiOnly().as('categories')
  })

  .prefix('/api/admin')
  .as('admin')
  .use(middleware.auth())
  .use(middleware.admin())

//  User-related routes
router
  .group(() => {
    router.get('/products/', [ProductController, 'index']).as('products.index')
    router.get('/products/:id', [ProductController, 'show']).as('products.show')

    router.get('/categories/', [CategoryController, 'index']).as('categories.index')
    router.get('/categories/:id', [CategoryController, 'show']).as('categories.show')

    router.get('/orders/', [OrderController, 'index']).as('orders.index')
    router.get('/orders/:id', [OrderController, 'show']).as('orders.show')
    router.post('/orders', [OrderController, 'store']).as('orders.store')

    router.get('/suppliers/', [SupplierController, 'index']).as('suppliers.index')
    router.get('/suppliers/:id', [SupplierController, 'show']).as('suppliers.show')

    router.get('/payments/', [PaymentController, 'index']).as('payments.index')
    router.get('/payments/:id', [PaymentController, 'show']).as('payments.show')
    router.post('/payments/', [PaymentController, 'store']).as('payments.store')

    router.get('/customers/', [CustomerController, 'index']).as('customers.index')
    router.get('/customers/:id', [CustomerController, 'show']).as('customers.show')
    router.post('/customers/', [CustomerController, 'store']).as('customers.store')
  })
  .use(middleware.auth())
  .prefix('/api')

router.get('/uploads/product-images/:filename', [ImagesController, 'show']).as('images.show')
