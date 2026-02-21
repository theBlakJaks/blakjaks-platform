package com.blakjaks.app

import io.mockk.every
import io.mockk.mockk
import com.blakjaks.app.core.network.AuthInterceptor
import com.blakjaks.app.core.storage.TokenManager
import okhttp3.*
import org.junit.Assert.*
import org.junit.Test

class AuthInterceptorTest {

    @Test
    fun `interceptor adds Authorization header when token exists`() {
        val tokenManager = mockk<TokenManager>()
        every { tokenManager.getAccessToken() } returns "test-token"

        val interceptor = AuthInterceptor(tokenManager)
        var capturedHeader: String? = null

        val chain = mockk<Interceptor.Chain>()
        val request = Request.Builder().url("http://example.com").build()
        every { chain.request() } returns request
        every { chain.proceed(any()) } answers {
            capturedHeader = firstArg<Request>().header("Authorization")
            Response.Builder()
                .request(firstArg())
                .protocol(Protocol.HTTP_1_1)
                .code(200)
                .message("OK")
                .body(ResponseBody.create(null, ""))
                .build()
        }

        interceptor.intercept(chain)
        assertEquals("Bearer test-token", capturedHeader)
    }

    @Test
    fun `interceptor does not add header when token is null`() {
        val tokenManager = mockk<TokenManager>()
        every { tokenManager.getAccessToken() } returns null

        val interceptor = AuthInterceptor(tokenManager)
        var capturedHeader: String? = null

        val chain = mockk<Interceptor.Chain>()
        val request = Request.Builder().url("http://example.com").build()
        every { chain.request() } returns request
        every { chain.proceed(any()) } answers {
            capturedHeader = firstArg<Request>().header("Authorization")
            Response.Builder()
                .request(firstArg())
                .protocol(Protocol.HTTP_1_1)
                .code(200)
                .message("OK")
                .body(ResponseBody.create(null, ""))
                .build()
        }

        interceptor.intercept(chain)
        assertNull(capturedHeader)
    }
}
