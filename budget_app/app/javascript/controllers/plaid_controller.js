import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = { exchangeUrl: String, createTokenUrl: String }

  async openLink() {
    const button = this.buttonTarget
    const originalText = button.textContent
    button.disabled = true
    button.textContent = "Connecting…"

    try {
      const tokenRes = await fetch(this.createTokenUrlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Content-Type": "application/json"
        }
      })

      if (!tokenRes.ok) throw new Error(`Server error ${tokenRes.status}`)

      const { link_token, error } = await tokenRes.json()
      if (error) throw new Error(error)

      const handler = window.Plaid.create({
        token: link_token,
        onSuccess: async (public_token, metadata) => {
          button.textContent = "Saving…"
          await this.exchangeToken(public_token, metadata)
        },
        onExit: (_err, _metadata) => {
          button.disabled = false
          button.textContent = originalText
        }
      })

      handler.open()
    } catch (e) {
      console.error("Plaid Link error:", e)
      button.disabled = false
      button.textContent = originalText
      alert("Could not open Plaid Link: " + e.message)
    }
  }

  async exchangeToken(publicToken, metadata) {
    const res = await fetch(this.exchangeUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ public_token: publicToken, metadata })
    })
    const data = await res.json()
    if (data.success) {
      window.location.href = window.location.href
    } else {
      alert("Failed to connect bank: " + (data.error || "Unknown error"))
      this.buttonTarget.disabled = false
      this.buttonTarget.textContent = "Connect a Bank"
    }
  }
}
