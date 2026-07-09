package com.example.eazzio_reminder

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

object AutoSendTracker {
    private const val TAG = "AutoSendTracker"
    var isAutoSendPending = false
    var pendingTime = 0L

    fun setPending() {
        Log.d(TAG, "AutoSendTracker set to pending")
        isAutoSendPending = true
        pendingTime = System.currentTimeMillis()
    }

    fun checkAndClear(): Boolean {
        val now = System.currentTimeMillis()
        val elapsed = now - pendingTime
        Log.d(TAG, "Checking pending status: isPending=$isAutoSendPending, elapsed=${elapsed}ms")
        if (isAutoSendPending && elapsed < 15000) { // 15 second window
            isAutoSendPending = false
            return true
        }
        isAutoSendPending = false
        return false
    }
}

class WhatsAppAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // We only care about TYPE_WINDOW_STATE_CHANGED or TYPE_WINDOW_CONTENT_CHANGED
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString()
        if (packageName != "com.whatsapp" && packageName != "com.whatsapp.w4b") {
            return
        }

        // Only auto-click if we recently requested an auto-send
        if (!AutoSendTracker.checkAndClear()) {
            return
        }

        val rootNode = rootInActiveWindow ?: return
        Log.d("WhatsAppAccessibility", "WhatsApp opened and auto-send is pending. Searching for send button...")

        // Attempt 1: Find by resource ID
        // WhatsApp send button ID is usually "com.whatsapp:id/send" or "com.whatsapp.w4b:id/send"
        val sendNodeIds = listOf(
            "com.whatsapp:id/send",
            "com.whatsapp.w4b:id/send",
            "com.whatsapp:id/send_button"
        )
        
        var clickSuccess = false
        
        for (id in sendNodeIds) {
            val nodes = rootNode.findAccessibilityNodeInfosByViewId(id)
            if (nodes != null && nodes.isNotEmpty()) {
                val sendButton = nodes[0]
                if (sendButton.isEnabled) {
                    sendButton.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    Log.d("WhatsAppAccessibility", "Successfully clicked WhatsApp send button by ID: $id")
                    clickSuccess = true
                    break
                }
            }
        }

        // Attempt 2: If ID search fails, search by content description or structure
        if (!clickSuccess) {
            val nodes = findSendButtonRecursively(rootNode)
            if (nodes != null) {
                nodes.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                Log.d("WhatsAppAccessibility", "Successfully clicked WhatsApp send button recursively")
                clickSuccess = true
            }
        }

        if (clickSuccess) {
            // Wait slightly and perform a back action to return to our app
            performBackActionDelayed()
        }
    }

    private fun findSendButtonRecursively(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        if (node == null) return null
        
        val contentDesc = node.contentDescription?.toString()?.lowercase()
        val className = node.className?.toString()
        
        // WhatsApp send button is typically an ImageButton or ImageView with description "send"
        if ((className == "android.widget.ImageButton" || className == "android.widget.ImageView") &&
            (contentDesc == "send" || contentDesc == "envoyer" || contentDesc == "enviar" || contentDesc == "kirim")) {
            return node
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val found = findSendButtonRecursively(child)
            if (found != null) {
                return found
            }
        }
        return null
    }

    private fun performBackActionDelayed() {
        Thread {
            try {
                // Wait for 1.5 seconds to allow WhatsApp to finish sending the message
                Thread.sleep(1500)
                // Go back once to exit the chat screen
                performGlobalAction(GLOBAL_ACTION_BACK)
                Thread.sleep(500)
                // Go back twice to return to our app
                performGlobalAction(GLOBAL_ACTION_BACK)
                Log.d("WhatsAppAccessibility", "Performed back actions to return to app")
            } catch (e: InterruptedException) {
                Log.e("WhatsAppAccessibility", "Delayed back action interrupted", e)
            }
        }.start()
    }

    override fun onInterrupt() {
        Log.d("WhatsAppAccessibility", "Accessibility Service Interrupted")
    }
}
