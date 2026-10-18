package com.muntasirashif.screen_shield

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

/*
 * Simple unit tests for the method-dispatch surface of the plugin. The plugin
 * touches the Activity window only when one is attached, so these calls are
 * exercised with no Activity bound (the null-safe default path).
 */
internal class ScreenShieldPluginTest {
    private fun invoke(plugin: ScreenShieldPlugin, method: String): MethodChannel.Result {
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(MethodCall(method, null), result)
        return result
    }

    @Test
    fun isEnabled_defaultsToTrue() {
        val result = invoke(ScreenShieldPlugin(), "isEnabled")
        Mockito.verify(result).success(true)
    }

    @Test
    fun isCaptured_defaultsToFalse() {
        val result = invoke(ScreenShieldPlugin(), "isCaptured")
        Mockito.verify(result).success(false)
    }

    @Test
    fun enable_returnsSuccess() {
        val result = invoke(ScreenShieldPlugin(), "enable")
        Mockito.verify(result).success(null)
    }

    @Test
    fun disable_returnsSuccess() {
        val result = invoke(ScreenShieldPlugin(), "disable")
        Mockito.verify(result).success(null)
    }

    @Test
    fun unknownMethod_isNotImplemented() {
        val result = invoke(ScreenShieldPlugin(), "nope")
        Mockito.verify(result).notImplemented()
    }
}
