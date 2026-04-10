import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), 350)
  }

  submitNow() {
    clearTimeout(this.timer)
    this.element.requestSubmit()
  }
}
