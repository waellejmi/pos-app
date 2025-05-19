import { configure } from '@japa/runner'
import { assert } from '@japa/assert'
import { apiClient } from '@japa/api-client'

// Configure the Japa runner
configure({
  files: ['tests/**/*.spec.ts'], // Ensure this matches your test file locations
  plugins: [assert(), apiClient()],
})
