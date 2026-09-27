// TJ-ARCH-MOB-001 compliant
package org.example.__APP_CRATE___mobile

import android.content.Intent
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.rule.ActivityTestRule
import dev.flutter.plugins.integration_test.FlutterTestRunner
import org.junit.Rule
import org.junit.runner.RunWith

@RunWith(FlutterTestRunner::class)
class MainActivityTest {
    @Rule
    @JvmField
    val rule = object : ActivityTestRule<MainActivity>(
        MainActivity::class.java,
        true,
        false,
    ) {
        override fun getActivityIntent(): Intent =
            Intent(
                InstrumentationRegistry.getInstrumentation().targetContext,
                MainActivity::class.java,
            ).apply {
                if (
                    InstrumentationRegistry.getArguments()
                        .getString("verifyRestart") == "true"
                ) {
                    putExtra("route", "/verify-restart")
                }
            }
    }
}
