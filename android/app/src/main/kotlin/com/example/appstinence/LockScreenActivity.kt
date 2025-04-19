package com.example.appstinence

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import com.example.appstinence.R

class LockScreenActivity : Activity() {
    private lateinit var passwordInput: EditText
    private lateinit var unlockButton: Button
    private var savedPassword: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        setContentView(R.layout.activity_lock_screen)

        passwordInput = findViewById(R.id.password_input)
        unlockButton = findViewById(R.id.unlock_button)

        val sharedPref: SharedPreferences = getSharedPreferences("app_block_data", Context.MODE_PRIVATE)
        val packageNameToCheck = intent.getStringExtra("package_name")

        val perAppPasswordKey = "pwd_$packageNameToCheck"
        savedPassword = sharedPref.getString(perAppPasswordKey, null)

        // fallback if not set
        if (savedPassword == null) {
            savedPassword = sharedPref.getString("password", null)
        }

        unlockButton.setOnClickListener {
            val enteredPassword = passwordInput.text.toString()
            if (enteredPassword == savedPassword) {
                finish()
            } else {
                Toast.makeText(this, "Incorrect password", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
