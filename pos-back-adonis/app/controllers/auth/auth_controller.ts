import User from '#models/user'
import { loginValidator, registerValidator, userUpdateValidator } from '#validators/auth'
import type { HttpContext } from '@adonisjs/core/http'
import db from '@adonisjs/lucid/services/db'

export default class AuthController {
  async register({ request }: HttpContext) {
    const data = await request.validateUsing(registerValidator)
    const user = await User.create(data)

    return User.accessTokens.create(user)
  }

  async login({ request }: HttpContext) {
    const { email, password } = await request.validateUsing(loginValidator)
    const user = await User.verifyCredentials(email, password)

    return User.accessTokens.create(user)
  }

  async logout({ auth }: HttpContext) {
    const user = auth.user!
    await User.accessTokens.delete(user, user.currentAccessToken.identifier)
    return { message: 'success' }
  }

  async me({ auth, response }: HttpContext) {
    const user = await auth.use('api').authenticate()

    await user.load('role')

    return response.ok(user)
  }

  async update({ auth, request, session, response }: HttpContext) {
    const { fullName, phone, address } = await request.validateUsing(userUpdateValidator)
    const trx = await db.transaction()
    auth.user!.useTransaction(trx)
    try {
      await auth.user!.merge({ fullName }).save()
      await auth.user!.merge({ phone }).save()
      await auth.user!.merge({ address }).save()
      await trx.commit()
    } catch (error) {
      await trx.rollback()
      session.flash('errorsBag.form', 'Something went wrong')
    }

    return response.created({ message: 'User Info Updated successfully' })
  }
}
