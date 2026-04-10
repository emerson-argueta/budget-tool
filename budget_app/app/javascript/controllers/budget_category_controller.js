import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["planned", "input"]
  static values = { updateUrl: String }

  startEdit() {
    this.plannedTarget.classList.add("hidden")
    this.inputTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  cancelEdit() {
    this.inputTarget.classList.add("hidden")
    this.plannedTarget.classList.remove("hidden")
  }

  async saveEdit(event) {
    if (event.type === "keydown" && event.key !== "Enter") return

    const amount = this.inputTarget.value
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    try {
      const res = await fetch(this.updateUrlValue, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: JSON.stringify({ planned_amount: amount })
      })

      if (res.ok) {
        const html = await res.text()
        Turbo.renderStreamMessage(html)
      } else {
        this.cancelEdit()
      }
    } catch (e) {
      console.error("Failed to update amount", e)
      this.cancelEdit()
    }
  }
}
